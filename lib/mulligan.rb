module Mulligan

  def self.supported?
    !!(defined?(RUBY_ENGINE) && RUBY_ENGINE == "ruby" && RUBY_VERSION >= "1.9.3")
  end

  def self.using_extension?
    supported? && RUBY_VERSION < "2.0.0"
  end


  # Defines a scope inside of which Kernel#signal can raise exceptions which can be
  # optionally rescued.
  if self.supported?
    def self.with_signal_activated
      Mulligan::Kernel.__send__(:__increment_automatic_continuing_scope_count__)
      yield if block_given?
    rescue => e
      unless recovery(IgnoringRecovery).nil?
        recover IgnoringRecovery
      end
      mg_raise
    ensure
      Mulligan::Kernel.__send__(:__decrement_automatic_continuing_scope_count__)
    end
  else
    def self.with_signal_activated
      yield if block_given?
    end
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

