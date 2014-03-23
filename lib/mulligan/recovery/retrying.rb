require 'mulligan/recovery'

module Mulligan
  class RetryingRecovery < Recovery
    self.summary =
<<END
Performs again the last task which caused the failure.
END
    self.discussion =
<<END
Attributes:
  'count' - The number of times this recovery has been invoked. In this way, you can keep track of how many times the code has been retried and perhaps limit the total number of retries.
END
    attr_reader :count

    def initialize
      @count = 0
    end

    def increment_count
      @count = @count + 1
    end
    
  end
end

