module Mulligan

  # Recover objects are the yang to Exception's yin. Together, they form a
  # cohesive whole.
  # When an exception is raised, Recovery objects can be attached which can be
  # processed in a rescue clause. A choice can be made and if a recovery is invoked,
  # a continuation will be taken, placing the program back at the site of the #raise
  # where the recovery can be applied and the program can continue executing.
  #
  # Recovery objects are designed to include enough metadata that they could be
  # presented to a human to choose the appropriate recovery should an exception
  # rise, unrescued, to the top-level.
  #
  # Recovery objects can also carry arguments from the raise site, with the intention
  # of passing information to a rescue clause.
  #
  # Library writers are encouraged to make a base recovery for their recoveries under
  # Mulligan::Recovery. For example:
  # 
  #   module MyProduct
  #     class Recovery < Mulligan::Recovery
  #     end
  #   end
  # 
  # If there is a superclass of recovery that your recovery can match in behavior,
  # consider subclassing it as code that chooses recoveries can choose the superclass
  # and get the best expected behavior.
  
  class Recovery

    class << self
      attr_accessor :summary, :discussion
    end

    attr_accessor :summary, :discussion
    
    def initialize(summary = nil)
      self.summary = summary
    end
    
    def inspect
      "#{self.class}: #{summary}"
    end
    
    # Executes the recovery which repairs the Exception at the site of the
    # '#raise' call which created the Exception
    # @param [Array] arguments arguments passed back to the recovery code
    # to be processed
    def invoke(*args)
      @continuation.call(*args) unless @continuation.nil?
    end
    
    # Describes the recovery so that a human could make an intelligent choice if
    # presented with a list from which to choose.
    def summary
      @summary || self.class.summary
    end
    
    # Describes the recovery so that a human could make an intelligent choice if
    # presented with a list from which to choose.
    def discussion
      @discussion || self.class.discussion
    end
    
  end
end
