module Mulligan
  module Exception
  
    # @return The list of recoveries available with this Exception
    def recoveries
      v = __recoveries__.keys
      # define an #inspect method on the array for use in Pry
      singleton = class << v ; self end
      r = __recoveries__
      singleton.send :define_method, :inspect do
        v.collect do |instance|
          s = "#{instance.class.name}\n" +
          "-" * instance.class.name.length + "\n" +
          instance.summary + "\n"
          s << instance.discussion + "\n" unless instance.discussion.nil?
        end.join("\n")
      end
      v
    end

  private
    def __set_recovery__(instance)
      __recoveries__[instance] = caller
    end

    def __chosen_recovery__(choice)
      # Ruby's Hash has ordered keys.
      # The first keys will have the deepest continuations which are closest to the
      # error
      return nil if choice.nil?
      __recoveries__.each do |k,v|
        return k if choice === k
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
