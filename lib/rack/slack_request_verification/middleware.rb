require 'logger'
require 'openssl'

module Rack::SlackRequestVerification
  class Middleware
    attr_reader *%i(
      signing_key
      path_pattern
      signing_version
      timestamp_header
      signature_header
      logger
      max_staleness_in_secs
    )

    def initialize(app,
      # A regular expression used to determine which requests to verify
      path_pattern:,

      # You can provide a signing key directly, set a SLACK_SIGNING_KEY env var
      # or customise the env var to something else
      signing_key: nil,
      signing_key_env_var: 'SLACK_SIGNING_KEY',

      # Mitigates replay attacks by verifying the request was sent recently –
      # a better strategy is to record the signature header to ensure you only
      # process each request once
      max_staleness_in_secs: 60 * 5,

      # Where to log error messages
      logger: Logger.new($stdout),

      signing_version: 'v0',
      timestamp_header: 'X-Slack-Request-Timestamp',
      signature_header: 'X-Slack-Signature'
    )
      @app = app
      @path_pattern = path_pattern
      @signing_version = signing_version
      @timestamp_header = timestamp_header
      @signature_header = signature_header
      @logger = logger
      @max_staleness_in_secs = max_staleness_in_secs

      @signing_key = signing_key || ENV.fetch(signing_key_env_var) do
        fail Error, "#{signing_key_env_var} env var not set, please configure a signing key"
      end
    end

    def call(env)
      if !path_pattern.match?(env['PATH_INFO'])
        @app.call(env)
      else
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

        @app.call(env)
      end
    end
  end
end
