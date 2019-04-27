module Rack::SlackRequestVerification
  class Request
    extend Forwardable
    attr_reader :env, :config
    def_delegators :config, :signature_header, :timestamp_header

    def initialize(env, config)
      @env = env
      @config = config
    end

    def path
      env.fetch('PATH_INFO')
    end

    def headers
      headers = {
        signature_header => env["HTTP_" + signature_header.gsub('-', '_').upcase],
        timestamp_header => env["HTTP_" + timestamp_header.gsub('-', '_').upcase]&.to_i
      }
    end

    def missing_headers
      headers.select { |_, value| value.nil? }.keys
    end

    def missing_headers?
      !missing_headers.empty?
    end

    def body
      @body ||= read_body!
    end

    def signed_signature
      headers.fetch(signature_header)
    end

    def timestamp
      headers.fetch(timestamp_header)
    end

    def computed_signature
      ComputedSignature.new(self)
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
