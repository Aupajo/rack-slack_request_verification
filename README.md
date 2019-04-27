# Rack::SlackRequestVerification

Rack middleware to verify Slack requests made using signed secrets.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rack-slack_request_verification'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rack-slack_request_verification

## Usage

Inside your `config.ru`:

```ruby
# Apply signed request verification to every path starting with "/slack/"
use Rack::SlackRequestVerification, path_pattern: %{^/slack/}
run MyApp
```

Will use a `SLACK_SIGNING_SECRET` environment variable by default.

You can override this with:

```ruby
use Rack::SlackRequestVerification, path_pattern: %{^/slack/}, signing_secret: '...'
```

A **401 Not Authorized** is returned in the following circumstances:

* When either or both of the `X-Slack-Request-Timestamp` or `X-Slack-Signature` headers are absent
* When the timestamp is more than five minutes old (to mitigate replay attacks)
* When the computed signature of the request does not match the `X-Slack-Signature`

A log message is also generated.

### Full options

```ruby
use Rack::SlackRequestVerification, {
    # A regular expression used to determine which requests to verify
    path_pattern: %r{^/slack/},

    # You can provide a signing secret directly, set a SLACK_SIGNING_SECRET
    # env var or customise the env var to something else
    signing_secret: nil,
    signing_secret_env_var: 'SLACK_SIGNING_SECRET',

    # Mitigates replay attacks by verifying the request was sent recently –
    # a better strategy is to record the signature header to ensure you only
    # process each request once
    max_staleness_in_secs: 60 * 5,

    # The entire request body must be loaded into memory to compute the hash.
    # To prevent a DDoS attack, the request body is limited to 1MB
    request_body_limit_in_bytes: 1024 ** 2,

    # Where to log error messages
    logger: Logger.new($stdout),

    # Settings as currently in use by Slack
    signing_version: 'v0',
    timestamp_header: 'X-Slack-Request-Timestamp',
    signature_header: 'X-Slack-Signature'
}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Aupajo/rack-slack_request_verification. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Rack::SlackRequestVerification project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/Aupajo/rack-slack_request_verification/blob/master/CODE_OF_CONDUCT.md).
