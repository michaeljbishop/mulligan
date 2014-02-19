require "mulligan/version"
require "mulligan/exception"
require "mulligan/kernel"

class Exception
  prepend Mulligan::Exception
end

class Object
  prepend Mulligan::Kernel
end

