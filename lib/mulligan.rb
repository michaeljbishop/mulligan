module Mulligan

  def self.supported?
    !!(defined?(RUBY_ENGINE) && RUBY_ENGINE == "ruby" && RUBY_VERSION >= "1.9.3")
  end

  def self.using_extension?
    supported? && RUBY_VERSION < "2.0.0"
  end
end

require "mulligan/exception"
require "mulligan/kernel"

class Exception
  include Mulligan::Exception
end

class Object
  include Mulligan::Kernel
end
