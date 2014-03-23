$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'mulligan'
require "mulligan/ignoring_recovery"
require "mulligan/missing_recovery_error"

  
#=======================
#    HELPER METHODS
#=======================

# returns the line given a string from Exception#backtrace
def line_from_stack_string(s)
  s.match(/[^:]+:(\d+)/)[1].to_i
end

#=======================
#    HELPER CLASSES
#=======================

class CustomException < Exception
end

class CustomObjectReturner
  def exception(*args)
    CustomException.new(*args)
  end
end

class DescriptiveRecovery < Mulligan::Recovery
  self.summary = "summary"
  self.discussion = "discussion"
end

