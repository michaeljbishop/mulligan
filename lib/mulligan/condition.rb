module Mulligan
  module Condition
  
    # @return The list of recoveries available with this Exception
    def recoveries
      v = __recoveries__.values
      # define an #inspect method on the array for use in Pry
      singleton = class << v ; self end
      r = __recoveries__
      singleton.send :define_method, :inspect do
        @inspect_message ||= r.collect do |klass, instance|
          s = "#{klass.name}\n" +
          "-" * klass.name.length + "\n" +
          instance.summary + "\n"
          s << instance.discussion + "\n" unless instance.discussion.nil?
        end.join("\n")
      end
      v
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

