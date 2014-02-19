require 'spec_helper'

describe Mulligan do
  it 'should have a version number' do
    Mulligan::VERSION.should_not be_nil
  end

  shared_examples "a Mulligan Exception" do
    it 'should propagate errors' do
      expect { inner_test(style) }.to raise_error
    end

    it 'should correctly report missing strategies' do
      inner_test(style){|e|e.restart_exist?(:aaa)}.should be_false
    end

    it 'should correctly report included strategies' do
      inner_test(style){|e|e.restart_exist?(:ignore)}.should be_true
    end

    it 'should raise a control exception when invoking a non-existent restart' do
      expect { inner_test(style){|e|e.restart :aaa} }.to raise_error(Mulligan::ControlException)
    end

    it 'should not raise an exception when invoking the ignore restart' do
      expect { inner_test(style){|e|e.restart :ignore} }.to_not raise_exception
    end

    it 'should return the parameter sent when invoking the return_param restart' do
      result = inner_test(style){|e|e.restart(:return_param, 5)}
      result.should be_eql(5)
    end
  end

  context Exception do
    let(:style){:manual}
    it_behaves_like "a Mulligan Exception"
  end

  context "Kernel#raise" do
    let(:style){:raise}
    it_behaves_like "a Mulligan Exception"
  end
end

def core_test(style)

  b = lambda do
    restart :ignore
    restart(:return_param){|p|p}
  end

  case style
  when :manual
    e = Exception.new("Test Exception", &b)
    raise e
  when :raise
    raise "Test Exception", &b
  end
end

def inner_test(style = :manual, &handler)
  core_test(style)
  rescue Exception => e
    handler.call(e)
end
