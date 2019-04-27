module Rack::SlackRequestVerification
  class Request
    extend Forwardable
    attr_reader :env, :config
    def_delegators :headers, :signed_signature, :timestamp
    def_delegators :config, :request_body_limit_in_bytes

    def initialize(env, config)
      @env = env
      @config = config
    end

    def path
      env.fetch('PATH_INFO')
    end

    def headers
      @headers ||= Headers.new(self)
    end

    def body
      input_rack_io = env.fetch('rack.input')
      bytes = input_rack_io.read(request_body_limit_in_bytes)

      # Attempt to read one more byte
      reading_is_complete = input_rack_io.read(1).nil?

      # Rewind for the next middleware
      input_rack_io.rewind

      fail RequestBodyTooLarge unless reading_is_complete

      bytes
    end

    def computed_signature
      @computed_signature ||= ComputedSignature.new(self)
    end
  end
end
