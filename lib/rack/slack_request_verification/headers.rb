module Rack::SlackRequestVerification
  class Headers
    extend Forwardable
    def_delegators :@config, :signature_header, :timestamp_header
    attr_reader :request, :to_h

    def initialize(request)
      @request = request
      @config = request.config

      @to_h = {
        signature_header => read(signature_header),
        timestamp_header => read(timestamp_header)&.to_i
      }
    end

    def signed_signature
      to_h.fetch(signature_header)
    end

    def timestamp
      to_h.fetch(timestamp_header)
    end

    def missing
      to_h.select { |_, value| value.nil? }.keys
    end

    def missing?
      !missing.empty?
    end

    private

    def read(header)
      request.env["HTTP_" + header.gsub('-', '_').upcase]
    end
  end
end
