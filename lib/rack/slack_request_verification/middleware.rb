require 'logger'
require 'openssl'
require 'openssl'

module Rack::SlackRequestVerification
  class Middleware < SimpleDelegator
    attr_reader :app

    def initialize(app, config)
      @app = app
      super(config)
    end

    def call(env)
      if path_pattern.match?(env['PATH_INFO'])
        headers = {
          signature_header => env["HTTP_" + signature_header.gsub('-', '_').upcase],
          timestamp_header => env["HTTP_" + timestamp_header.gsub('-', '_').upcase]&.to_i
        }

        missing_headers = headers.select { |_, value| value.nil? }.keys

        if !missing_headers.empty?
          logger.error "Slack verification failed: missing #{missing_headers.join(', ')}"
          return [401, {}, "Not authorized"]
        end

        timestamp = headers[timestamp_header]
        signature = headers[signature_header]

        minimum_timestamp = Time.now.to_i - max_staleness_in_secs

        if timestamp < minimum_timestamp
          logger.error "Slack verification failed: #{timestamp_header} is #{timestamp}, only #{minimum_timestamp} or later is allowed"
          return [401, {}, "Not authorized"]
        end

        body = env['rack.input']

        signature_base_string = [
          signing_version,
          timestamp,
          body.read
        ].join(':')

        body.rewind

        digest = OpenSSL::HMAC.hexdigest("SHA256", signing_key, signature_base_string)

        computed_signature = [signing_version, digest].join('=')

        if computed_signature != signature
          logger.error "Slack verification failed: #{signature_header} does not match the signature"
          return [401, {}, "Not authorized"]
        end
      end

      app.call(env)
    end
  end
end
