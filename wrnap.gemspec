# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wrnap/version'

Gem::Specification.new do |spec|
  spec.name          = "wrnap"
  spec.version       = Wrnap::VERSION
  spec.authors       = ["Evan Senter"]
  spec.email         = ["evansenter@gmail.com"]
  spec.summary       = %q{A comprehensive wrapper (wRNApper) for various RNA CLI programs.}
  spec.description   = %q{}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"

  spec.add_runtime_dependency "activesupport", "~> 4.0"
  spec.add_runtime_dependency "shuffle",       "~> 0.1"
  spec.add_runtime_dependency "rinruby",       "~> 2.0"
  spec.add_runtime_dependency "rroc",          "~> 0.1"
end