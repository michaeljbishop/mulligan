module Mulligan

  def self.supported?
    !!(defined?(RUBY_ENGINE) && RUBY_ENGINE == "ruby" && RUBY_VERSION >= "1.9.3")
  end

  def self.using_extension?
    supported? && RUBY_VERSION < "2.0.0"
  end
end

require "mulligan/condition"
require "mulligan/kernel"

class Exception
  include Mulligan::Condition
end

class Object
  if RUBY_VERSION < "2.0"
    # ruby 1.9 replaces raise in the extension
    include Mulligan::Kernel
  else
    prepend Mulligan::Kernel
  end
end
