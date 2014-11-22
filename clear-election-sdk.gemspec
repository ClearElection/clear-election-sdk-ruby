# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'clear-election-sdk/version'

Gem::Specification.new do |spec|
  spec.name          = "clear-election-sdk"
  spec.version       = ClearElection::VERSION
  spec.authors       = ["ronen barzel"]
  spec.email         = ["ronen@barzel.org"]
  spec.summary       = %q{Ruby SDK for working with ClearElection descriptions}
  spec.description   = %q{Ruby SDK for working with ClearElection descriptions.  Also includes factory for testing}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday"
  spec.add_dependency "json-schema"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end