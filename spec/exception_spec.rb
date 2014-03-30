require 'spec_helper'

describe Mulligan::Exception do
  describe "#recoveries" do
    it 'contains the collected recoveries' do
      begin
        case recovery
        when r = Recovery.new
        when i = IgnoringRecovery.new
        else ; mg_raise ; end
      rescue => e
        if Mulligan.supported?
          expect(e.recoveries).to eq [r,i]
        else
          expect(e.recoveries).to be_empty
        end
      end
    end

    describe "#inspect" do
      it "shows the complete documentation for all the recoveries" do
        begin
          case recovery
          when r = Recovery.new{|r| r.summary = "summary"}
          when i = IgnoringRecovery.new{|i| i.summary = "summary2"}
          else ; mg_raise ; end
        rescue => e
          r.discussion = "discussion"
          i.discussion = "discussion2"
          if Mulligan.supported?
           expect(e.recoveries.inspect).to eq <<__END
Mulligan::Recovery
------------------
summary
discussion

Mulligan::IgnoringRecovery
--------------------------
summary2
discussion2
__END
          else
            expect(e.recoveries.inspect).to eq("")
          end
        end
      end
    end

    describe "#__find_common_frame__" do
      common = 
      ["/irb/ruby-lex.rb:228:in `each_top_level_statement'",
       "/irb.rb:155:in `eval_input'",
       "/irb.rb:70:in `block in start'",
       "/irb.rb:69:in `catch'",
       "/irb.rb:69:in `start'"]

      it "correctly finds the frame when a is a superstack of b" do
        a = ["/irb/ruby-lex.rb:228:in `each_top_level_statement'"].concat common
        result = subject.send(:__find_common_frame__, a, common)
        expect(result).to eq 1
      end

      it "correctly finds the frame when b is a superstack of a" do
        a = ["/irb/ruby-lex.rb:228:in `each_top_level_statement'"].concat common
        result = subject.send(:__find_common_frame__, common, a)
        expect(result).to eq 0
      end

      it "correctly finds the frame when a differs from b by the first frame" do
        a = ["/irb/ruby-lex.rb:228:in `each_top_level_statement'"].concat common
        b = ["/irb/ruby-lex2.rb:228:in `each_top_level_statement'"].concat common
        result = subject.send(:__find_common_frame__, a, b)
        expect(result).to eq 1
      end

      it "correctly finds there is no commonality" do
        a = ["/irb/ruby-lex.rb:228:in `each_top_level_statement'"]
        b = ["/irb/ruby-lex2.rb:228:in `each_top_level_statement'"]
        result = subject.send(:__find_common_frame__, a, b)
        expect(result).to eq -1
      end
    end
  end
end
