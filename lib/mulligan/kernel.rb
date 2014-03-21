if Mulligan.using_extension?
  require "mulligan/mulligan"
end

module Mulligan

  # An exception that is thrown when invoking a non-existent recovery.
  class ControlException < Exception
  end

  module Kernel

    # Executes the recovery.
    # This actually places the current execution point to the code in the case
    # statement that specified the recovery
    # 
    # @param [Class] choice the class of the recovery
    # @return This doesn't actually matter because you can't retrieve it
    def recover(choice, *args)
      __execute_recovery__(choice, *args)
    end

    # Serves two functions:
    #   1. Begins a case statement where recoveries are defined
    #   2. Returns the recovery instance for the choice when in a rescue clause
    # 
    # @param [Class] choice the class of the recovery
    # @return Either the recovery instance or a 'collector' that builds recoveries
    #         in a case statement
    def recovery(choice = nil)
      return __start_case__ if choice.nil?
      raise "No Current Exception" if $!.nil?
      $!.send(:__chosen_recovery__, choice)
    end

  private
    def __start_case__
      Thread.current[:__last_recovery_collector] = Mulligan::Collector.new
    end

    def __execute_recovery__(choice = nil, *args)
      raise "No Current Exception" if $!.nil?
      # find the best match for the chosen recovery
      $!.__send__(:__execute_recovery__, choice, *args)
    end

    def self.__process_exception_from_raise__(e)
      matcher = Thread.current[:__last_recovery_collector]
      return if matcher.nil?
      matcher.__send__(:__add_recoveries_to_exception__, e)
      Thread.current[:__last_recovery_collector] = nil
    end
  end
end
