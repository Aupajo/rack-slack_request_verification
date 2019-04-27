require 'openssl'
require 'forwardable'

module Rack::SlackRequestVerification
  class ComputedSignature
    extend Forwardable
    def_delegators :@config, :signing_secret, :signing_version
    def_delegators :@request, :body, :timestamp

    def initialize(request)
      @request = request
      @config = request.config
    end

    def to_s
      [signing_version, digest].join('=')
    end

    def ==(other)
      other == to_s
    end

    private

    def signature_base_string
      [signing_version, timestamp, body].join(':')
    end

    def digest
      OpenSSL::HMAC.hexdigest("SHA256", signing_secret, signature_base_string)
    end
  end
end
