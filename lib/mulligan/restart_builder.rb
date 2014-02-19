module Mulligan
  class RestartBuilder < Object
  
    def initialize(*args, &block)
      @block = block
    end
  
    def restart(id, &block)
      block = ::Kernel::lambda{} if block.nil?
      @collected_restarts[id] = block
    end
  
  private
    def __restarts__
      @restarts ||= begin
        @collected_restarts = {}
        self.instance_exec(&@block) unless @block.nil?
        @collected_restarts
      end
    end
  
  end
end
