lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rack/slack_request_verification/version"

Gem::Specification.new do |spec|
  spec.name          = "rack-slack_request_verification"
  spec.version       = Rack::SlackRequestVerification::VERSION
  spec.authors       = ["Pete Nicholls"]
  spec.email         = ["aupajo@gmail.com"]

  spec.summary       = %q{Rack middleware to verify Slack requests made using signed secrets.}
  spec.homepage      = "https://github.com/Aupajo/rack-slack_request_verification"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "timecop"
end
