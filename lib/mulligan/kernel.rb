module Mulligan
  module Kernel
    def raise(*args, &block)
      super
    rescue Exception => e
      block.call(e) unless block.nil?

      # only use callcc if there are restarts otherwise re-raise it
      super(e) if e.send(:restarts).empty?
      callcc do |c|
        e.send(:__set_continuation__, c)
        super(e)
      end
    end
  end
end
