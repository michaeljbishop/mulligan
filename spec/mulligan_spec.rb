require 'spec_helper'

include Mulligan

class RootRecovery < Recovery
end
 
class ReturningAllParametersRecovery < Recovery
  attr_reader :arguments
  def initialize(*args)
    @arguments = args
  end
end
 
class SubclassRecovery < RootRecovery
end
 
describe Mulligan do
  it 'should have a version number' do
    Mulligan::VERSION.should_not be_nil
  end

  describe "#recovery in a case statement" do

    it 'should pick up recoveries by class and attach them to an exception object' do
      exception = begin
        case recovery
        when IgnoringRecovery
        else ; raise ; end
      rescue => e ; e
      end
      expect(exception.recoveries.first.is_a? IgnoringRecovery).to eq(Mulligan.supported?)
    end

    it 'should pick up recoveries by instance and attach them to an exception object' do
      exception = begin
        case recovery
        when IgnoringRecovery.new
        else ; raise ; end
      rescue => e ; e
      end
      expect(exception.recoveries.first.is_a? IgnoringRecovery).to eq(Mulligan.supported?)
    end

    it 'should pick up recoveries by class only once and attach them to an exception object' do
      exception = begin
        case recovery
        when IgnoringRecovery
        when IgnoringRecovery
        else ; raise ; end
      rescue => e ; e
      end
      expect(exception.recoveries.count).to Mulligan.supported? ? be(1) : be(0)
    end

    it 'should pick up recoveries by instance only once and attach them to an exception object' do
      exception = begin
        case recovery
        when IgnoringRecovery.new
        when IgnoringRecovery.new
        else ; raise ; end
      rescue => e ; e
      end
      expect(exception.recoveries.count).to Mulligan.supported? ? be(1) : be(0)
    end

    it 'should pick up recoveries by class and instance only once and attach them to an exception object' do
      exception = begin
        case recovery
        when IgnoringRecovery.new
        when IgnoringRecovery
        else ; raise ; end
      rescue => e ; e
      end
      expect(exception.recoveries.count).to Mulligan.supported? ? be(1) : be(0)
    end

  end
  
  context "when choosing a recovery by class" do

    it 'should only have executed the code in the case once' do
      times = 0
      exception = begin
        case recovery
        when begin
          times = times + 1
          IgnoringRecovery
        end
        else ; raise ; end
      rescue => e
        recover IgnoringRecovery
      end
      expect(times).to eq(1)
    end

    describe "#recover when recovering from an exception" do
      it 'should execute the first matching subclass' do
        result = begin
          case recovery
          when IgnoringRecovery
            1
          when Recovery
            2
          else ; raise ; end
        rescue => e
          next e unless Mulligan.supported?
          recover Recovery
        end
      expect(result).to Mulligan.supported? ? be(1) : be_a(RuntimeException)
      end

      it 'should execute the most specific subclass' do
        result = begin
          case recovery
          when Recovery
            2
          when IgnoringRecovery
            1
          else ; raise ; end
        rescue => e
          next e unless Mulligan.supported?
          recover IgnoringRecovery
        end
      expect(result).to Mulligan.supported? ? be(1) : be_a(RuntimeException)
      end

      it 'should pass the recovery arguments' do
        a = [Object.new, Object.new]
        result = begin
          case recovery
          when ReturningAllParametersRecovery.new(*a)
            a
          else ; raise ; end
        rescue => e
          next e unless Mulligan.supported?
          r = recovery(ReturningAllParametersRecovery)
          expect(r).to_not be_nil
          expect(r.arguments).to eq(a)
          recover ReturningAllParametersRecovery, *r.arguments
        end
        expect(result).to Mulligan.supported? ? eq(a) : be_a(RuntimeException)
      end

      it 'should receive arguments specified in recover statement'
      
    end

  end
  
end
