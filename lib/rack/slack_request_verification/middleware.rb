require 'logger'
require 'openssl'
require 'delegate'

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

      begin
        if path_pattern.match?(request.path)
          if request.headers.missing?
            logger.error "Slack verification failed: missing #{request.headers.missing.join(', ')}"
            return respond_with(401)
          end

          if request.timestamp < minimum_timestamp
            logger.error "Slack verification failed: #{timestamp_header} is #{request.timestamp}, only #{minimum_timestamp} or later is allowed"
            return respond_with(401)
          end

          if request.computed_signature != request.signed_signature
            logger.error "Slack verification failed: #{signature_header} does not match the signature"
            return respond_with(401)
          end
        end
      rescue RequestBodyTooLarge
        logger.error "Slack verification failed: request exceeded limit of #{request_body_limit_in_bytes} bytes"
        return respond_with(413)
      end

      app.call(env)
    end

    def respond_with(code)
      body = Rack::Utils::HTTP_STATUS_CODES.fetch(code)
      [code, {}, [body]]
    end
  end
end
