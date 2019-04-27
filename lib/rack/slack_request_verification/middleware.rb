require 'logger'
require 'openssl'
require 'forwardable'

module Rack::SlackRequestVerification
  class Middleware < SimpleDelegator
    attr_reader :app, :config

    def initialize(app, config)
      @app = app
      @config = config
      super(config)
    end

    def call(env)
      request = Request.new(env, config)

      if path_pattern.match?(request.path)
        if request.missing_headers?
          logger.error "Slack verification failed: missing #{request.missing_headers.join(', ')}"
          return [401, {}, "Not authorized"]
        end

        if request.timestamp < minimum_timestamp
          logger.error "Slack verification failed: #{timestamp_header} is #{request.timestamp}, only #{minimum_timestamp} or later is allowed"
          return [401, {}, "Not authorized"]
        end

        if request.computed_signature != request.signed_signature
          logger.error "Slack verification failed: #{signature_header} does not match the signature"
          return [401, {}, "Not authorized"]
        end
      end

      app.call(env)
    end
  end
end
