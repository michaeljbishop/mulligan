require 'spec_helper'

describe Mulligan::Kernel do
  describe "#recovery" do
    describe "in a \'case\' statement" do

      it 'collects recoveries by class' do
        exception = begin
          case recovery
          when IgnoringRecovery
          else ; raise ; end
        rescue => e ; e
        end
        expect(exception.recoveries.first.is_a? IgnoringRecovery).to eq(Mulligan.supported?)
      end

      it 'collects recoveries by instance' do
        exception = begin
          case recovery
          when IgnoringRecovery.new
          else ; raise ; end
        rescue => e ; e
        end
        expect(exception.recoveries.first.is_a? IgnoringRecovery).to eq(Mulligan.supported?)
      end

      it 'collects recoveries by class, ignoring duplicate classes' do
        exception = begin
          case recovery
          when IgnoringRecovery
          when IgnoringRecovery
          else ; raise ; end
        rescue => e ; e
        end
        expect(exception.recoveries.count).to Mulligan.supported? ? be(1) : be(0)
      end

      it 'collects recoveries by instance ignoring duplicate instances' do
        exception = begin
          case recovery
          when IgnoringRecovery.new
          when IgnoringRecovery.new
          else ; raise ; end
        rescue => e ; e
        end
        expect(exception.recoveries.count).to Mulligan.supported? ? be(1) : be(0)
      end

      it 'collects recoveries by class and instance, ignoring duplicates' do
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

    describe "when passed a class in a \'rescue\' clause" do

      it 'selects the first matching subclass' do
        begin
          case recovery
          when i = IgnoringRecovery.new
          when r = Recovery.new
          else ; raise ; end
        rescue => e
          next e unless Mulligan.supported?
          expect(recovery(Recovery)).to Mulligan.supported? ? be(i) : be_nil
        end
      end

      it 'selects the most specific subclass' do
        begin
          case recovery
          when r = Recovery.new
          when i = IgnoringRecovery.new
          else ; raise ; end
        rescue => e
          expect(recovery(IgnoringRecovery)).to Mulligan.supported? ? be(i) : be_nil
        end
      end

      it 'selects the recovery closest to the original error' do
        begin
          case recovery
          when r = Recovery.new
          else ; raise ; end
        rescue => e
          begin
            case recovery
            when r2 = Recovery.new
            else ; raise e ; end
          rescue => e2
            expect(recovery(Recovery)).to Mulligan.supported? ? be(r) : be_nil
          end
        end
      end
    end

    it "raises RuntimeError when passed a selector and there is no current Exception" do
      expect($!).to be_nil
      expect {recovery IgnoringRecovery}.to raise_error(RuntimeError)
    end
  end

  describe "#recover" do
    it "executes the recovery code unless unsupported" do
      result = begin
        case recovery
        when Recovery
          5
        else ; raise ; end
      rescue => e
        recover Recovery
        6
      end
      expect(result).to eq(Mulligan.supported? ? 5 : 6)
    end
    
    it "raises a MissingRecoveryError if no recovery can be found" do
      next unless Mulligan.supported?
      expect do
        begin
          raise
        rescue => e
          expect(e.recoveries).to be_empty
          recover Recovery
        end
      end.to raise_error(MissingRecoveryError)
    end

    context "when raising a MissingRecoveryError" do
      it "attaches a RetryingRecovery" do
        result = begin
          case recovery
          when IgnoringRecovery
            5
          else
            raise
          end
        rescue => e
          begin
            recover Recovery
          rescue MissingRecoveryError
            expect(recovery RetryingRecovery).to_not be_nil
          end
        end
      end

      it "invoking the RetryingRecovery with a new choice succeeds" do
        result = begin
          case recovery
          when IgnoringRecovery
            5
          else
            raise
          end
        rescue => e
          begin
            recover RetryingRecovery
            rescue MissingRecoveryError
              recover RetryingRecovery, IgnoringRecovery
          end
          5
        end
        expect(result).to eq(5)
      end

      it "attaches a RetryingRecovery that keeps count of the retries" do
        retrying_recovery = nil
        result = begin
          case recovery
          when IgnoringRecovery
          else
            raise
          end
        rescue => e
          count = 0
          begin
            recover RetryingRecovery
          rescue MissingRecoveryError
            retrying_recovery = recovery(RetryingRecovery)
            if (count < 2)
              count += 1
              recover RetryingRecovery
            else
              count += 1
              recover RetryingRecovery, IgnoringRecovery
            end
          end
          5
        end
        if Mulligan.supported?
          expect(retrying_recovery.count).to eq(3)
        else
          expect(result).to eq(5)
        end
      end
    end
    
    it 'passes the arguments to the recovery code through #recovery' do
      begin
        case r = recovery
        when Recovery
          expect(r.argv).to eq([5,6])
        else ; raise ; end
      rescue => e
        recover Recovery, 5, 6
      end
    end
    
    it "raises RuntimeError when there is no current Exception" do
      expect($!).to be_nil
      expect { recover Recovery }.to raise_error(RuntimeError)
    end
  end

  if Mulligan.using_extension?
    describe "#raise (C-extension)" do
      it "reports the proper line" do
        begin
          line = __LINE__ ; raise "Test"
        rescue => e
          expect(line_from_stack_string(e.backtrace[0])).to eq(line)
        end
      end

      context "when called with no arguments" do
        it "raises the last active exception" do
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
    
        it "raises a RuntimeError if there is no last active exception"  do
          expect { raise }.to raise_error(RuntimeError)
        end
      end
  
      it "raises a RuntimeError with string message when called with a single string" do
        message = "test"
        begin
          raise message
        rescue RuntimeError => e
          expect(e.message).to eq(message)
        end
      end

      it "raises an error when called with two strings" do
        expect{ raise("hello", "world") }.to raise_error
      end
  
      context "when called with a Exception subclass class object" do
        it "raises an instance of that subclass" do
          expect{ raise CustomException }.to raise_error(CustomException)
        end
      end

      context "when called with an object instance" do
        let(:object){ CustomObjectReturner.new }

        it "raises the result of calling object.exception" do
          expect{ raise object }.to raise_error(CustomException)
        end

        context "and a string" do
          it "raises the result of calling object.exception with a custom message" do
            begin
              raise object, "test"
            rescue CustomException => e
              expect(e.message).to eq("test")
            end
          end
        end
      end
    end
  end
end
  
