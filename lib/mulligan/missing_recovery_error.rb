require 'mulligan/error'

module Mulligan
  class MissingRecoveryError < Error
    attr_reader :cause
    attr_reader :chosen_recovery
    def initialize(chosen_recovery)
      @chosen_recovery = chosen_recovery
      @cause = $!
    end
  end
end

