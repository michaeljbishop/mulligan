# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mulligan/version'

Gem::Specification.new do |spec|
  spec.name          = "mulligan"
  spec.version       = Mulligan::VERSION
  spec.required_ruby_version='~> 2.0'
  spec.authors       = ["michaeljbishop"]
  spec.email         = ["mbtyke@gmail.com"]
  spec.summary       = %q{Adds restarts to Ruby's Exception class (similar to LISP Conditions)}
  spec.description   = <<__END__
Allows you to decouple the code implementing a exception-handling strategy from the code which decides which strategy to use.

In other words, when you handle a Mulligan::Condition in your rescue clause, you can choose from a set of strategies (called "restarts") exposed by the exception to take the stack back to where #raise was called, execute your strategy, and pretend that the exception was never raised.
__END__
  spec.homepage      = "http://michaeljbishop.github.io/mulligan"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.extensions    = %w[ext/mulligan/extconf.rb]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rake-compiler"
end
