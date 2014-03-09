require 'continuation'

module Mulligan
  module Kernel

    # Returns the identifier for the last recovery invoked in this thread.
    # @return [Symbol] The identifier of the last recovery invoked in this thread.
    def last_recovery
      Thread.current[:__last_recovery__]
    end
  end
end
