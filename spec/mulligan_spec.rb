require 'spec_helper'

describe Mulligan do
  it 'should have a version number' do
    Mulligan::VERSION.should_not be_nil
  end

  shared_examples "a Mulligan Condition" do
    it 'should propagate errors' do
      expect { outer_test(style) }.to raise_error
    end

    it 'should correctly report missing strategies' do
      outer_test(style){|e|e.has_recovery?(:aaa)}.should be_false
    end

    it 'should correctly report included strategies' do
      outer_test(style){|e|e.has_recovery?(:ignore)}.should be_true
    end

    it 'should correctly report the list of recoveries' do
      outer_test(style){|e|e.recovery_identifiers}.should == [:ignore, :return_param, :return_all_params, :return_param2, :retry]
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

    it 'should return all parameters sent when invoking the return_all_params recovery' do
      result1, result2 = outer_test(style){|e|e.recover(:return_all_params, 5, 6)}
      result1.should eq(5)
      result2.should eq(6)
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
    
    it "should retrieve the network request without an exception" do
      @count_of_calls_before_failure = 2

      result = nil
      expect { result = do_network_task }.to_not raise_error
      expect(result).to eq(
        {
          :users    => "json_data",
          :posts    => "json_data",
          :comments => "json_data"
        }
      )
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

      it "should pass data created in set_recovery" do
        data = nil
        outer_test(style) do |e|
          data = e.recovery_options(:return_param)[:data]
          e.recover(:return_param)
        end
        expect(data).to be(5)
      end

      it "should pass summary created in set_recovery" do
        data = nil
        outer_test(style) do |e|
          data = e.recovery_options(:return_param)[:summary]
          e.recover(:return_param)
        end
        expect(data).to eq("Passes the parameter sent in as the value of the block.")
      end

      it "should be read-only" do
        result = outer_test(style) do |e|
          e.recovery_options(:return_param)[:new_entry] = 5
          e.recover(:return_param, e)
        end
        expect(result.recovery_options(:return_param)[:new_entry]).to be_nil
      end

      if Exception.method_defined?(:cause)
        it "should support the `#cause` method in the native extension" do
          begin
            raise "test"
          rescue => e
            begin
              raise "test2"
            rescue =>e
             expect(e.cause.message).to eq "test"
            end
          end
        end
      end

      it "should support overriding a recovery and calling the inherited recovery"
    end
  end
    
  context Exception do
    let(:style){:manual}
    it_behaves_like "a Mulligan Condition"

    it "shouldn't fail when recovering before raising" do
      t = Exception.new("Test Exception")
      t.set_recovery(:ignore) {|p|}
      expect{t.recover(:ignore)}.to_not raise_error
    end
  end

  shared_examples "raising exceptions" do
    it_behaves_like "a Mulligan Condition"

    it "should propgate recoveries when raising a pre-existing exception" do
      t = Exception.new("Test Exception")
      t.set_recovery(:ignore) {|p|}
      begin
        raise t do |e|
          e.set_recovery(:return_param){|p|p}
        end
      rescue Exception => e
        expect(e.has_recovery?:ignore).to be_true
      end
    end

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

    it "should modify variables in the binding of the raiser" do
      begin
        result = scope_test
      rescue => e
        e.recover :change
      end
      expect(result).to eq(7)
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

    it "should raise a TypeError when called with two strings" do
      expect {
        raise "hello", "world"
      }.to raise_error(TypeError)
    end
    
    it "should, when called with a Exception subclassclass, raise that subclass" do
      expect {
        raise CustomException
      }.to raise_error(CustomException)
    end

    context "when called with an object instance," do
      let(:object){CustomObjectReturner.new}

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

  describe "Kernel#raise" do
    let(:style){:raise}
    it_behaves_like "raising exceptions"
  end
end


class CustomException < Exception
end

class CustomObjectReturner
  def exception(*args)
    CustomException.new(*args)
  end
end


#=======================
#    HELPER METHODS
#=======================

def scope_test
  result = 5
  raise do |e|
    e.set_recovery :change do |arg|
      result = 7
    end
  end
  result
end





#=======================
#    HELPER METHODS
#=======================

# returns the line given a string from Exception#backtrace
def line_from_stack_string(s)
  s.match(/[^:]+:(\d+)/)[1].to_i
end

def core_test(style)
  t =  "Test Exception"
  t = Exception.new("Test Exception") if style == :manual
  raise t do |e|
    e.set_recovery(:ignore){|p|p}
    e.set_recovery(:no_block)
    e.set_recovery(:return_param, data: 5, summary: "Passes the parameter sent in as the value of the block."){|p|p}
    e.set_recovery(:return_all_params){|*p|next *p}
    e.set_recovery(:return_param2){|p|p}
  end
end


def inner_test(style = :manual)
  core_test(style)
rescue Exception => e
  result = raise(e) do |e|
    e.set_recovery(:retry){}
  # here we add 10 so we can ensure we are in fact, overriding
  # the behavior for the same recovery as defined in core_test
    e.set_recovery(:return_param2){|p|p+10}
  end
  retry if last_recovery == :retry
  # here we add 10 so we can differentiate retries in `inner_test` from `core_test`
  # we know we are in inner_test if our result is plus 10
  result + 10
end


def outer_test(style = :manual, &handler)
  inner_test(style)
rescue Exception => e
  handler.call(e)
end



#===========================
#   SIMULATE LOGIN EXPIRE
#===========================

# simple method that logs the user in

@credentials = "password"
def login
  @credentials = "password"
  @count_of_calls_before_failure = 2
end


class CredentialsExpiredException < Exception ; end

# at a low level, we will just raise a CredentialsExpiredException if that's
# the response we get from the server
def rest_get(url)
  # simulate that the credentials expire after a certain period
  @credentials = nil if @count_of_calls_before_failure <= 0
  @count_of_calls_before_failure = @count_of_calls_before_failure - 1

  # Simulate getting a response from the server indicating our credentials
  # have expired.
  raise(CredentialsExpiredException, "Credentials expired") if @credentials != "password"

  # Canned data to return
  "json_data"
end

# this takes a resource, makes an URL for that and returns the raw data provided
# from rest_get.
# It also specifies a "retry" recovery in case the credentials can be restored by
# code at a higher level
def request_resource(name)
  url = "http://site.com/#{name}"
  rest_get(url)
  
rescue CredentialsExpiredException => e
  # re-raise the exception but add a recovery so if they fix the credentials
  # we can try again
  raise (e) do |e|
    e.set_recovery(:retry){true}
  end
  retry if last_recovery == :retry
  result
end

# This is the method that demonstrates how it all comes together.
# We can handle all credential failures from a very high-level.
# Because #request_resource offers a retry recovery, any code that calls
# #request_resource doesn't have to worry about the state of the user's credentials.
# Those exceptions will be thrown and the handling of them will at a very high-level
# of abstraction, yet, after they are handled, the program will continue as if the
# exception hadn't been thrown to begin with.
def do_network_task
  {
    :users    => request_resource("users"),   # This one should work
    :posts    => request_resource("posts"),   # This one should work
    :comments => request_resource("comments") # This one should fail
  }
  
  # Here, we handle any requests where credentials fail and we re-login
  # then we ask to retry the same query
rescue CredentialsExpiredException => e
  login
  e.recover :retry
end
