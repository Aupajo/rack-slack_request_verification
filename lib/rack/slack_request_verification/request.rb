module Rack::SlackRequestVerification
  class Request
    extend Forwardable
    attr_reader :env, :config
    def_delegators :headers, :signed_signature, :timestamp

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
      @body ||= read_body!
    end

    def computed_signature
      @computed_signature ||= ComputedSignature.new(self)
    end

    private

    def read_body!
      input_rack_io = env.fetch('rack.input')
      read = input_rack_io.read.dup
      input_rack_io.rewind
      read
    end
  end
end
