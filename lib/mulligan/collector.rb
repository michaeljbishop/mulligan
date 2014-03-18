require 'continuation' if Mulligan.supported?

module Mulligan

  # Private class used by the Mulligan system to build a list
  # of recoveries to be attached to an Exception class that can
  # be processed in a rescue.
  class Collector
    attr_reader :args

    def initialize
      @recoveries = {}
      @args = []
    end
    
  private
    def __add_recovery__(recovery)
      # we want to make sure we have one entry per recovery class
      @recoveries[recovery.class] = recovery
    end
    
    def __add_recoveries_to_exception__(e)
      @recoveries.each do |k,v|
        e.__send__(:__set_recovery__, v)
      end
    end

    def __set_args__(args)
      @args = args
    end
  end

  class Recovery
    def ===(other)
      return super unless Mulligan.supported?
      return super unless other.is_a?(Mulligan::Collector)
      callcc do |c|
        @continuation = proc do |recovery, *args|
          other.__send__(:__set_args__, args) 
          c.call(true)
        end
        other.__send__(:__add_recovery__, self)
        false
      end
    end

    def self.===(other)
      return super unless other.is_a?(Mulligan::Collector)
      self.new === other
    end
  end
end

