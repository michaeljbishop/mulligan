require 'spec_helper'

include Mulligan

describe Condition do
  describe "#recoveries" do
    it 'contains the collected recoveries' do
      begin
        case recovery
        when r = Recovery.new
        when i = IgnoringRecovery.new
        else ; raise ; end
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
          when r = Recovery.new("summary")
          when i = IgnoringRecovery.new("summary2")
          else ; raise ; end
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
  end
end
