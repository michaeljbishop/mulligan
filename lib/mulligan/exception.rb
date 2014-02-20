require 'continuation'

module Mulligan

  class ControlException < Exception ; end

  module Exception

    def set_restart(id, options={}, &block)
      return if block.nil?
      restarts[id.to_sym] = options.merge(:block => block)
    end
    
    def restart_exist?(id)
      restarts.has_key?(id.to_sym)
    end
    
    def restart_options(id)
      return nil unless restart_exist?(id.to_sym)
      restarts[id.to_sym].dup.reject{|k,v| [:block, :continuation].include? k}
    end
  
    def restart_invoke(id, *params)
      raise ControlException unless restart_exist?(id.to_sym)
      data = restarts[id.to_sym]
      if data[:continuation].nil?
        $stderr.puts "Cannot invoke restart #{id}. Must first raise this exception (#self)"
        return
      end
      data[:continuation].call(data[:block].call(*params))
    end
  
  private

    def restarts
      @restarts ||= {}
    end

    def __set_continuation__(continuation)
      # the the continuation for any restarts that are not yet assigned one
      restarts.each do |key, r|
        next if r.has_key? :continuation
        r[:continuation] = continuation
      end
    end
  end
end

