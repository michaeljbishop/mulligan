module Mulligan
  class ContinuingRecovery < Recovery
    self.summary =
<<END
Ignores the exception and continues execution.
END
    self.discussion =
<<END
If this recovery is attached to an Exception, you may safely continue.
END
  end
end

