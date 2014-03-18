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
  class Recovery

    attr_accessor :message
    attr_accessor :arguments
    
    # Creates a Recovery with arguments to be processed in a rescue clause
    def initialize(*arguments)
      self.arguments = arguments
    end
    
    # Executes the recovery which repairs the Exception at the site of the
    # '#raise' call which created the Exception
    # @param [Array] arguments arguments passed back to the recovery code
    # to be processed
    def invoke(*arguments)
      @continuation.call(*arguments) unless @continuation.nil?
    end
    
    # Describes the recovery so that a human could make an intelligent choice if
    # presented with a list from which to choose.
    def message
      @message || default_message
    end
    
    protected
    
    def default_message
      "default"
    end
  end
end
