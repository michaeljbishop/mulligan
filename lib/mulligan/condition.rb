require 'continuation'

module Mulligan

  # An exception that is thrown when invoking a non-existent recovery.
  class ControlException < Exception ; end

  module Condition

    # Creates or replaces a recovery strategy.
    # 
    # @param [String or Symbol] id the key to reference the recovery later
    # @param [String] options specifies a token for this recovery that can later be
    #                 retrieved. Can only be set once.
    def set_recovery(id, options={}, &block)
      return if block.nil?
      restarts[id.to_sym] = options.merge(:block => block)
      nil
    end
    
    # Checks for the presence of a recovery
    # 
    # @param [String or Symbol] id the key for the recovery
    # @return [Boolean] whether or not a recovery exists for this id
    def recovery_exist?(id)
      restarts.has_key?(id.to_sym)
    end
    
    # Retrieves the options specified when a recovery was made
    # 
    # @param [String or Symbol] id the key for the recovery
    # @return [Hash] The options set on this recovery
    def recovery_options(id)
      return nil unless recovery_exist?(id.to_sym)
      restarts[id.to_sym].dup.reject{|k,v| [:block, :continuation].include? k}
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
      raise ControlException unless recovery_exist?(id.to_sym)
      data = restarts[id.to_sym]
      if data[:continuation].nil?
        $stderr.puts "Cannot invoke restart #{id}. Must first raise this exception (#self)"
        return
      end
      data[:continuation].call(data[:block].call(*params))
    end
  
  private

    def restarts
      @restarts ||= {}
    end

    def __set_continuation__(continuation)
      # the the continuation for any restarts that are not yet assigned one
      restarts.each do |key, r|
        next if r.has_key? :continuation
        r[:continuation] = continuation
      end
    end
  end
end

