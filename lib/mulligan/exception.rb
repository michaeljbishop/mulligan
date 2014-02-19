require 'continuation'
require_relative 'restart_builder.rb'

module Mulligan

  class ControlException < Exception ; end

  module Exception
  #   attr_reader :restart_data

    def initialize(*args, &block)
      return super(*args) if block.nil?

      __load_builder__(&block)

      # save off the self of the block that is defining all the restarts
      # it is that binding with which we will need to invoke the actual
      # restart code
      @raiser_self = if block.binding.respond_to? :local_variable_get
        block.binding.local_variable_get(:self )
      else
        block.binding.eval('self')
      end
      super(*args)
    end
  
    def restart_exist?(id)
      restarts.has_key?(id.to_sym)
    end
  
    def restart(id, *params)
      data = restarts[id.to_sym]
      raise ControlException if data.nil?

      @continuation.call(@raiser_self.instance_exec(*params, &data))
    end
  
  private

    def restarts
      return @builder.__send__( :__restarts__) unless @builder.nil?
      {}
    end

    def __load_builder__(&block)
      @builder = RestartBuilder.new(&block) unless block.nil?
    end

    def __builder__
      @builder
    end

    def __set_continuation__(continuation)
      @continuation = continuation
    end
  end
end

