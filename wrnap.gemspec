# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wrnap/version'

Gem::Specification.new do |spec|
  spec.name          = "wrnap"
  spec.version       = Wrnap::VERSION
  spec.authors       = ["Evan Senter"]
  spec.email         = ["evansenter@gmail.com"]
  spec.summary       = %q{A comprehensive wrapper w(RNA)pper for various RNA CLI programs.}
  spec.description   = %q{}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.0"

  spec.add_development_dependency "awesome_print",      "~> 1.2"
  spec.add_development_dependency "bundler",            "~> 1.7"
  spec.add_development_dependency "gem-release",        "~> 0.7"
  spec.add_development_dependency "rake",               "~> 10.4"
  spec.add_development_dependency "minitest-reporters", "~> 1.0"
  
  spec.add_runtime_dependency "activesupport",    "~> 4.0"
  spec.add_runtime_dependency "bio",              "~> 1.4"
  spec.add_runtime_dependency "bio-stockholm",    "~> 0.0.1"
  spec.add_runtime_dependency "entrez",           "~> 0.5"
  spec.add_runtime_dependency "meta_missing",     "~> 0.3.0"
  spec.add_runtime_dependency "numbers_in_words", "~> 0.2.0"
  spec.add_runtime_dependency "parallel",         "~> 1.3", ">= 1.3.2"
  spec.add_runtime_dependency "rinruby",          "~> 2.0"
  spec.add_runtime_dependency "rroc",             "~> 0.1"
  spec.add_runtime_dependency "ruby-progressbar", "~> 1.5", ">= 1.5.1"
  spec.add_runtime_dependency "rubytree",         "~> 0.9"
  spec.add_runtime_dependency "shuffle",          "~> 1.0", ">= 1.0.1"
  spec.add_runtime_dependency "virtus",           "~> 1.0", ">= 1.0.4"
end
