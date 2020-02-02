require 'rack/test'

RSpec.describe 'Middleware configuration' do
  def configure(**args)
    mock_app = double(:app)
    Rack::SlackRequestVerification.new(mock_app, **args)
  end

  around do |example|
    original_env = ENV.to_h
    ENV.replace({})
    example.call
    ENV.replace(original_env)
  end

  it 'supports a signing secret option' do
    middleware = configure(signing_secret: 'explicit', path_pattern: %r{/slack/})
    expect(middleware.signing_secret).to eq 'explicit'
  end

  it 'supports a signing secret env var' do
    expect { configure(path_pattern: %r{/slack/}) }
    .to raise_error(Rack::SlackRequestVerification::Error, /SLACK_SIGNING_SECRET/)

    ENV['SLACK_SIGNING_SECRET'] = 'from-env-var'

    middleware = configure(path_pattern: %r{/slack/})
    expect(middleware.signing_secret).to eq 'from-env-var'
  end

  it 'supports a signing secret env var option' do
    expect { configure(signing_secret_env_var: 'CUSTOM_KEY', path_pattern: %r{/slack/}) }
    .to raise_error(Rack::SlackRequestVerification::Error, /CUSTOM_KEY/)

    ENV['CUSTOM_KEY'] = 'from-env-var'

    middleware = configure(signing_secret_env_var: 'CUSTOM_KEY', path_pattern: %r{/slack/})
    expect(middleware.signing_secret).to eq 'from-env-var'
  end

  it 'fails if no signing key or path pattern is given' do
    expect { configure }.to raise_error(ArgumentError)
  end

  it 'fails if no path pattern is given' do
    expect { configure(signing_secret: 'present') }
      .to raise_error(ArgumentError, /path_pattern/)
  end

  it 'can have a path pattern' do
    middleware = configure(signing_secret: 'present', path_pattern: %r{^/slack/})
    expect(middleware.path_pattern).to eq %r{^/slack/}
  end
end
