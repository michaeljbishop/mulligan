require "mulligan/version"
require "mulligan/condition"
require "mulligan/kernel"

class Exception
  prepend Mulligan::Condition
end

class Object
  prepend Mulligan::Kernel
end

