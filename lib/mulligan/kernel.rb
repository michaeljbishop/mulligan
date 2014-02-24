module Mulligan
  module Kernel

    # Raises an Exception.
    # The Exception that is either passed in or generated is yielded to the block
    # where you can specify recoveries on it.
    # 
    # @param args the same args you would pass to the normal Kernel#raise
    # @yield [e] Passes the exception-to-be-raised to the block.
    # @return The value returned from the invoked recovery block.
    def raise(*args, &block)
      super
    rescue Exception => e
      block.call(e) unless block.nil?

      # only use callcc if there are restarts otherwise re-raise it
      super(e) if e.send(:recoveries).empty?
      callcc do |c|
        e.send(:__set_continuation__, c)
        super(e)
      end
    end
    
    # Returns the identifier for the last recovery invoked in this thread.
    # @return [Symbol] The identifier of the last recovery invoked in this thread.
    def last_recovery
      Thread.current[:__last_recovery__]
    end
  end
end
