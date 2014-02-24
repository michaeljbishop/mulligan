require 'continuation'

module Mulligan

  # An exception that is thrown when invoking a non-existent recovery.
  class ControlException < Exception ; end

  module Condition

    # Creates or replaces a recovery strategy.
    # 
    # @param [String or Symbol] id the key to reference the recovery later
    # @param [Hash] options specifies a token for this recovery that can later be
    #               retrieved. Can only be set once. See {#recovery_options}
    #               Reserved Keys are as follows:
    #                 :data       - Use this as a parameter to send a piece of data to rescuers to use
    #                               as they determine their strategy for recovering.
    #                 :summary    - A short, one-line description of this recovery
    #                 :discussion - The complete documentation of this recovery. Please include a
    #                               description of the behavior, the return parameter, and any parameters
    #                               the recovery can take
    def set_recovery(id, options={}, &block)
      return if block.nil?
      recoveries[id.to_sym] = options.merge(:block => block)
      nil
    end
    
    # Checks for the presence of a recovery
    # 
    # @param [String or Symbol] id the key for the recovery
    # @return [Boolean] whether or not a recovery exists for this id
    def recovery_exist?(id)
      recoveries.has_key?(id.to_sym)
    end
    
    # Retrieves the options specified when a recovery was made
    # 
    # @param [String or Symbol] id the key for the recovery
    # @return [Hash] The options set on this recovery
    def recovery_options(id)
      return nil unless recovery_exist?(id.to_sym)
      recoveries[id.to_sym].dup.reject{|k,v| [:block, :continuation].include? k}
    end
  
    # Executes the recovery.
    # This actually places the stack back to just after the `#raise` that brought
    # us to this `rescue` clause. Then the recovery block is executed and the program
    # continues on.
    # 
    # @param [String or Symbol] id the key for the recovery
    # @param params any additional parameters you want to pass to the recovery block
    # @return This doesn't actually matter because you can't retrieve it
    def recover(id, *params)
      Thread.current[:__last_recovery__] = nil
      raise ControlException unless recovery_exist?(id.to_sym)
      data = recoveries[id.to_sym]
      if data[:continuation].nil?
        $stderr.puts "Cannot invoke restart #{id}. Must first raise this exception: '#{self.inspect}'"
        return
      end
      Thread.current[:__last_recovery__] = id
      data[:continuation].call(data[:block].call(*params))
    end
  
  private

    def recoveries
      @recoveries ||= {}
    end

    def __set_continuation__(continuation)
      # the the continuation for any recoveries that are not yet assigned one
      # It's important not to overwrite the existing continuations because a recovery
      # should return to the place it was raised, always.
      recoveries.each do |key, r|
        next if r.has_key? :continuation
        r[:continuation] = continuation
      end
    end
  end
end

