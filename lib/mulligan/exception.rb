module Mulligan
  module Exception
  
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
        return v if choice === v
      end
      nil
    end

    def __execute_recovery__(choice = nil, *args)
      r = __chosen_recovery__(choice)
      mg_raise MissingRecoveryError.new(choice) if r.nil? && Mulligan.supported?
      r.invoke(*args) unless r.nil?
    end

    def __recoveries__
      @recoveries ||= {} # class => instance
    end
    
    def __find_common_frame__(other)
      self.class.send(:__find_common_frame__, backtrace, other)
    end
    
    def self.__find_common_frame__(trace_a, trace_b)
      return -1 if trace_a.nil? or trace_b.nil?
      # returns the line given a string from Exception#backtrace
      def self.stack_string_without_line(s)
        s.match(/([^:]+:)\d+/)[1]
      end
      # positive if a > b
      a_offset = trace_a.length - trace_b.length
      index = [0, a_offset].max
      while (index < trace_a.length)
        frame_a = stack_string_without_line(trace_a[index])
        frame_b = stack_string_without_line(trace_b[index-a_offset])
        return index if frame_a == frame_b
        index += 1
      end
      -1
    end
  end
end
