require 'spec_helper'
require 'mulligan/version'

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

  describe "#with_signal_activated" do
    it "raises exceptions without continuing recoveries" do
      expect do
        Mulligan.with_signal_activated do
          raise
        end
      end.to raise_error(RuntimeError)
    end

    it "handles exception with a continue recovery" do
      test_case = proc do
        Mulligan.with_signal_activated do
          case recovery
          when ContinuingRecovery
          else ; mg_raise ; end
        end
      end
      if Mulligan.supported?
        expect(&test_case).to_not raise_error
      else
        expect(&test_case).to raise_error
      end
    end

    it "keeps the scope even when leaving it and recovering back into it" do
      saved_scope = 0
      begin
        Mulligan.with_signal_activated do
          saved_scope = Mulligan::Kernel.send(:__automatic_continuing_scope_count__)
          case recovery
          when RetryingRecovery
            expect(saved_scope).to eq(Mulligan::Kernel.send(:__automatic_continuing_scope_count__))
          else ; mg_raise ; end
        end
      rescue RuntimeError => e
        recover RetryingRecovery
      end
    end

    pending "starts a new scope when starting a thread" do
      Mulligan.with_signal_activated do
        t = Thread.start do
          case recovery
          when ContinuingRecovery
          else ; mg_raise ; end
          5
        end
        expect(t.value).to eq (5)
      end
    end
  end

end
