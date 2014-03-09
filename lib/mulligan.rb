require "mulligan/version"
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
