require_relative 'kernel_common'

module Mulligan
  module Kernel

    # Raises an Exception.
    # The Exception that is either passed in or generated is yielded to the block
    # where you can specify recoveries on it.
    # 
    # @param args the same args you would pass to the normal Kernel#raise
    # @yield [e] Passes the exception-to-be-raised to the block.
    # @return The value returned from the invoked recovery block.
    def raise(*args)
      super
    rescue Exception => e
      yield e if block_given?
      super(e) unless Mulligan.supported?
      
      # only use callcc if there are restarts otherwise re-raise it
      super(e) if e.send(:recoveries).empty?
      should_raise = true
      result = callcc do |c|
        e.send(:__set_continuation__) do |*args,&block|
          should_raise = false
          c.call(*args,&block)
        end
      end
      super(e) if should_raise
      result
    end
    
  end
end
