require 'logger'

module Rack::SlackRequestVerification
  class Configuration
    attr_reader *%i(
      signing_secret
      path_pattern
      signing_version
      timestamp_header
      signature_header
      logger
      max_staleness_in_secs
      request_body_limit_in_bytes
    )

    def initialize(
      # A regular expression used to determine which requests to verify
      path_pattern:,

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

      signing_version: 'v0',
      timestamp_header: 'X-Slack-Request-Timestamp',
      signature_header: 'X-Slack-Signature'
    )
      @path_pattern = path_pattern
      @signing_version = signing_version
      @timestamp_header = timestamp_header
      @signature_header = signature_header
      @logger = logger
      @max_staleness_in_secs = max_staleness_in_secs
      @request_body_limit_in_bytes = request_body_limit_in_bytes

      @signing_secret = signing_secret || ENV.fetch(signing_secret_env_var) do
        fail Error, "#{signing_secret_env_var} env var not set, please configure a signing secret"
      end
    end

    def minimum_timestamp
      Time.now.to_i - max_staleness_in_secs
    end
  end
end
