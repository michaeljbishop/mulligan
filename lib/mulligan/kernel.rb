require 'mulligan/recovery/retrying'
require "mulligan/collector"

if Mulligan.supported?
  if Mulligan.using_extension?
    require "mulligan/mulligan"
  else
    tp = TracePoint.new(:raise) do |tp|
      Mulligan::Kernel.__process_exception_from_raise__(tp.raised_exception)
    end.enable
  end
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
    # @raise MissingRecoveryError if Mulligan is supported AND the choice cannot be
    #                             found. Attached is a RetryingRecovery.
    def recover(choice, *args)
      __execute_recovery__(choice, *args)
    rescue MissingRecoveryError
      case r = recovery
      # use ||= because we only want to make one of these, even if we retry and
      # go through this code again
      when Mulligan::RetryingRecovery.new do |rr|
        rr.summary = <<END
Make another choice for a recovery.
END
        rr.discussion = <<END
This will attempt a new recovery in the context of the old attempt.
Arguments:
  <new_choice> - pass a new choice to attempt a recovery
END
        end
        choice = r.argv[0] unless r.argv[0].nil?
        rest = r.argv[1..-1]
        args   = rest unless rest.nil? || rest.empty?
        retry
      else
        raise
      end
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

    def __execute_recovery__(choice, *args)
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
