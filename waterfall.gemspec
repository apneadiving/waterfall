# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'waterfall/version'

Gem::Specification.new do |spec|
  spec.name          = "waterfall"
  spec.version       = Waterfall::VERSION
  spec.authors       = ["Benjamin Roth"]
  spec.email         = ["apnea.diving.deep@gmail.com"]
  spec.description   = %q{A way to chain ruby services, like promises (or monads)}
  spec.summary       = %q{A way to chain ruby services, like promises (or monads)}
  spec.homepage      = "https://github.com/apneadiving/waterfall"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "pry", '>0.10'
  spec.add_development_dependency "pry-nav"
  spec.add_development_dependency "rake"
end
