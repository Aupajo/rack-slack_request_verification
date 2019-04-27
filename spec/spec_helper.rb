require "bundler/setup"
require "rack/slack_request_verification"
require "rack/test"

module RequestHelpers
  include Rack::Test::Methods

  def app
    @app ||= Rack::Builder.new do
      use Rack::SlackRequestVerification, {
        signing_key: 'signing_key',
        path_pattern: %r{^/slack/}
      }

      run -> (env) { [200, {}, ['Echo: ', env['rack.input'].read]] }
    end
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include RequestHelpers
end
