require "bundler/setup"
require "rack/slack_request_verification"
require "rack/test"

module TestHelpers
  include Rack::Test::Methods

  def app
    @app ||= Rack::Builder.new do
      use Rack::SlackRequestVerification, {
        signing_secret: 'signing_secret',
        path_pattern: %r{^/slack/}
      }

      run -> (env) { [200, {}, ['Echo: ', env['rack.input'].read]] }
    end
  end

  # Freezes time in a way that discards microseconds, to work around a Timecop
  # issue.
  def safely_freeze_time(time, &block)
    parsed_time = Time.parse(time)
    safe_time = Time.parse(parsed_time.iso8601)
    Timecop.freeze(safe_time, &block)
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

  config.include TestHelpers
end
