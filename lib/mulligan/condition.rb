module Mulligan
  module Condition
  
    # @return The list of recoveries available with this Exception
    def recoveries
      __recoveries__.values
    end

  private
    def __set_recovery__(instance)
      # we want to make sure we have one entry per recovery class and the
      # recoveries closest to the error take priority.
      return if __recoveries__.has_key? instance.class
      __recoveries__[instance.class] = instance
    end

    def __chosen_recovery__(choice)
      # Ruby's Hash has ordered keys.
      # The first keys will have the deepest continuations which are closest to the
      # error
      return nil if choice.nil?
      __recoveries__.each do |k,v|
        return v if v.kind_of?(choice)
      end
      nil
    end

    def __execute_recovery__(choice = nil, *args)
      r = __chosen_recovery__(choice)
      r.invoke(*args) unless r.nil?
    end

    def __recoveries__
      @recoveries ||= {} # class => instance
    end
    
  end
end

