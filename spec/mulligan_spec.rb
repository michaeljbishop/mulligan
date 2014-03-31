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
          when IgnoringRecovery
          else ; mg_raise ; end
        end
      end
      if Mulligan.supported?
        expect(&test_case).to_not raise_error
      else
        expect(&test_case).to raise_error
      end
    end

    pending "starts a new scope when starting a thread" do
      Mulligan.with_signal_activated do
        t = Thread.start do
          case recovery
          when IgnoringRecovery
          else ; mg_raise ; end
          5
        end
        expect(t.value).to eq (5)
      end
    end
  end

end
