module Mulligan
  module Kernel
    def raise(*args, &block)
      super(*args)
    rescue Exception => e
      e.__send__(:__load_builder__, &block) unless block.nil?
      callcc{|c| e.send(:__set_continuation__, c); super(e)}
    end
  end
end
