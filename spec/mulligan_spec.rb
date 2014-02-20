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
      outer_test(style){|e|e.restart_exist?(:aaa)}.should be_false
    end

    it 'should correctly report included strategies' do
      outer_test(style){|e|e.restart_exist?(:ignore)}.should be_true
    end

    it 'should raise a control exception when invoking a non-existent restart' do
      expect { outer_test(style){|e|e.restart_invoke :aaa} }.to raise_error(Mulligan::ControlException)
    end

    it 'should not raise an exception when invoking the ignore restart' do
      expect { outer_test(style){|e|e.restart_invoke :ignore} }.to_not raise_exception
    end

    it 'should return the parameter sent when invoking the return_param restart' do
      result = outer_test(style){|e|e.restart_invoke(:return_param, 5)}
      result.should be(5)
    end

    context "and follows the continutation to the correct raise" do
      it 'should return the parameter sent when invoking the return_param restart' do
        result = outer_test(style){|e|e.restart_invoke(:return_param2, 5)}
        result.should be(25)
      end
    end
    
    it "should ignore setting a restart when passed no block" do
      expect { outer_test(style){|e|e.restart_invoke :no_block} }.to raise_error(Mulligan::ControlException)
    end
    
    describe "restart options" do
      it "should not return the block" do
        data = nil
        outer_test(style) do |e|
          data = e.restart_options(:return_param)[:block]
          e.restart_invoke(:return_param)
        end
        expect(data).to be_nil
      end

      it "should pass data created in set_restart" do
        data = nil
        outer_test(style) do |e|
          data = e.restart_options(:return_param)[:data]
          e.restart_invoke(:return_param)
        end
        expect(data).to be(5)
      end

      it "should be read-only" do
        result = outer_test(style) do |e|
          e.restart_options(:return_param)[:new_entry] = 5
          e.restart_invoke(:return_param, e)
        end
        expect(result.restart_options(:return_param)[:new_entry]).to be_nil
      end
    end
    
    it "should support overriding a restart and calling the inherited restart"
  end

  context Exception do
    let(:style){:manual}
    it_behaves_like "a Mulligan Exception"

    it "shouldn't fail when calling a restart before raising" do
      t = Exception.new("Test Exception")
      t.set_restart(:ignore) {|p|}
      expect{t.restart_invoke(:ignore)}.to_not raise_error
    end
  end

  context "Kernel#raise" do
    let(:style){:raise}
    it_behaves_like "a Mulligan Exception"

    it "should propgate restarts when raising a pre-existing exception" do
      t = Exception.new("Test Exception")
      t.set_restart(:ignore) {|p|}
      begin
        raise t do |e|
          e.set_restart(:return_param){|p|p}
        end
      rescue Exception => e
        expect(e.restart_exist?:ignore).to be_true
      end
    end
  end
end

def core_test(style)
  t =  "Test Exception"
  t = Exception.new("Test Exception") if style == :manual
  raise t do |e|
    e.set_restart(:ignore){|p|p}
    e.set_restart(:no_block)
    e.set_restart(:return_param, data: 5){|p|p}
    e.set_restart(:return_param2){|p|p}
  end
end

def inner_test(style = :manual)
  core_test(style)
  rescue Exception => e
    should_retry = false
    result = raise(e) do |e|
      e.set_restart(:retry){should_retry = true}
      # here we add 10 so we can ensue we are in fact, overriding
      # the behavior for the same restart as defined in core_test
      e.set_restart(:return_param2){|p|p+10}
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
