require 'spec_helper'

describe "Kernel#raise" do
  it "should properly report the line when raising with no block" do
    begin
      line = __LINE__ ; raise "Test"
    rescue => e
      expect(line_from_stack_string(e.backtrace[0])).to eq(line)
    end
  end

  it "should properly report the line when raising WITH a block" do
    begin
      line = __LINE__ ; raise "Test" do |e|
        false
      end
    rescue => e
      expect(line_from_stack_string(e.backtrace[0])).to eq(line)
    end
  end

  context "when raise is called with no arguments" do
    it "should raise $! when $! is not nil" do
      begin
        raise Exception, "test"
      rescue Exception => e
        expect($!).to be(e)
        begin
          raise
        rescue Exception => e2
          expect(e2).to be(e)
        end
      end
    end
    
    it "should raise a RuntimeError when $! is nil"  do
      expect { raise }.to raise_error(RuntimeError)
    end
  end
  
  it "should raise a RuntimeError with string message when raise is called only with a string" do
    message = "test"
    begin
      raise message
    rescue RuntimeError => e
      expect(e.message).to eq(message)
    end
  end

  it "should raise an error when called with two strings" do
    expect{ raise("hello", "world") }.to raise_error
  end
  
  it "should, when called with a Exception subclassclass, raise that subclass" do
    expect{ raise CustomException }.to raise_error(CustomException)
  end

  context "when called with an object instance," do
    let(:object){ CustomObjectReturner.new }

    it "should raise the result of calling object.exception" do
      expect{ raise object }.to raise_error(CustomException)
    end

    it "and a string, should raise the result of calling object.exception with a custom message" do
      begin
        raise object, "test"
      rescue CustomException => e
        expect(e.message).to eq("test")
      end
    end
  end
end

#=======================
#    HELPER METHODS
#=======================

# returns the line given a string from Exception#backtrace
def line_from_stack_string(s)
  s.match(/[^:]+:(\d+)/)[1].to_i
end

#=======================
#    HELPER CLASSES
#=======================

class CustomException < Exception
end

class CustomObjectReturner
  def exception(*args)
    CustomException.new(*args)
  end
end
