module Rack::SlackRequestVerification
  Error = Class.new(StandardError)
  RequestBodyTooLarge = Class.new(Error)
end
