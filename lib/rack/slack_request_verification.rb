module Rack
  module SlackRequestVerification
    class Error < StandardError; end

    def self.new(*args)
      Middleware.new(*args)
    end
  end
end

require "rack/slack_request_verification/version"
require "rack/slack_request_verification/middleware"
