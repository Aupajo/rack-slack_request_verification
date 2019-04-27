require 'forwardable'

module Rack
  module SlackRequestVerification
    def self.new(app, *args)
      config = Configuration.new(*args)
      Middleware.new(app, config)
    end
  end
end

require "rack/slack_request_verification/version"
require "rack/slack_request_verification/errors"
require "rack/slack_request_verification/middleware"
require "rack/slack_request_verification/configuration"
require "rack/slack_request_verification/request"
require "rack/slack_request_verification/headers"
require "rack/slack_request_verification/computed_signature"
