require 'spec_helper'

describe Mulligan do
  it 'should have a version number' do
    Mulligan::VERSION.should_not be_nil
  end

  shared_examples "a Mulligan Exception" do
    it 'should propagate errors' do
      expect { outer_test(style) }.to raise_error
    end

    it 'should correctly report missing strategies' do
      outer_test(style){|e|e.recovery_exist?(:aaa)}.should be_false
    end

    it 'should correctly report included strategies' do
      outer_test(style){|e|e.recovery_exist?(:ignore)}.should be_true
    end

    it 'should raise a control exception when invoking a non-existent recovery' do
      expect { outer_test(style){|e|e.recover :aaa} }.to raise_error(Mulligan::ControlException)
    end

    it 'should not raise an exception when invoking the ignore recovery' do
      expect { outer_test(style){|e|e.recover :ignore} }.to_not raise_exception
    end

    it 'should return the parameter sent when invoking the return_param recovery' do
      result = outer_test(style){|e|e.recover(:return_param, 5)}
      result.should be(5)
    end

    context "and follows the continutation to the correct raise" do
      it 'should return the parameter sent when invoking the return_param recovery' do
        result = outer_test(style){|e|e.recover(:return_param2, 5)}
        result.should be(25)
      end
    end
    
    it "should ignore setting a recovery when passed no block" do
      expect { outer_test(style){|e|e.recover :no_block} }.to raise_error(Mulligan::ControlException)
    end
    
    describe "recovery options" do
      it "should not return the block" do
        data = nil
        outer_test(style) do |e|
          data = e.recovery_options(:return_param)[:block]
          e.recover(:return_param)
        end
        expect(data).to be_nil
      end

      it "should not return the continuation" do
        data = nil
        outer_test(style) do |e|
          data = e.recovery_options(:return_param)[:continuation]
          e.recover(:return_param)
        end
        expect(data).to be_nil
      end

      it "should pass data created in set_restart" do
        data = nil
        outer_test(style) do |e|
          data = e.recovery_options(:return_param)[:data]
          e.recover(:return_param)
        end
        expect(data).to be(5)
      end

      it "should be read-only" do
        result = outer_test(style) do |e|
          e.recovery_options(:return_param)[:new_entry] = 5
          e.recover(:return_param, e)
        end
        expect(result.recovery_options(:return_param)[:new_entry]).to be_nil
      end
    end
    
    it "should support overriding a recovery and calling the inherited recovery"
  end

  context Exception do
    let(:style){:manual}
    it_behaves_like "a Mulligan Exception"

    it "shouldn't fail when recovering before raising" do
      t = Exception.new("Test Exception")
      t.set_recovery(:ignore) {|p|}
      expect{t.recover(:ignore)}.to_not raise_error
    end
  end

  context "Kernel#raise" do
    let(:style){:raise}
    it_behaves_like "a Mulligan Exception"

    it "should propgate recoveries when raising a pre-existing exception" do
      t = Exception.new("Test Exception")
      t.set_recovery(:ignore) {|p|}
      begin
        raise t do |e|
          e.set_recovery(:return_param){|p|p}
        end
      rescue Exception => e
        expect(e.recovery_exist?:ignore).to be_true
      end
    end
  end
end


#=======================
#    HELPER METHODS
#=======================

def core_test(style)
  t =  "Test Exception"
  t = Exception.new("Test Exception") if style == :manual
  raise t do |e|
    e.set_recovery(:ignore){|p|p}
    e.set_recovery(:no_block)
    e.set_recovery(:return_param, data: 5){|p|p}
    e.set_recovery(:return_param2){|p|p}
  end
end


def inner_test(style = :manual)
  core_test(style)
  rescue Exception => e
    should_retry = false
    result = raise(e) do |e|
      e.set_recovery(:retry){should_retry = true}
      # here we add 10 so we can ensure we are in fact, overriding
      # the behavior for the same recovery as defined in core_test
      e.set_recovery(:return_param2){|p|p+10}
    end
    retry if should_retry
    # here we add 10 so we can differentiate retries in `inner_test` from `core_test`
    # we know we are in inner_test if our result is plus 10
    result + 10
end


def outer_test(style = :manual, &handler)
  inner_test(style)
  rescue Exception => e
    handler.call(e)
end
