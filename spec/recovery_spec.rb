require 'spec_helper'

include Mulligan

describe Recovery do

  describe "#new" do
    it "overrides the summary" do
      d = DescriptiveRecovery.new("test")
      expect(d.summary).to eq "test"
    end
  end

  describe "#inspect" do
    it "lists the class and summary" do
      d = DescriptiveRecovery.new
      expect(d.inspect).to eq "DescriptiveRecovery: summary"
    end
  end

  describe "#invoke" do
    it "executes the continuation" do
      d = DescriptiveRecovery.new
      standin = proc{5}
      d.instance_eval{@continuation = standin}
      expect(d.invoke).to eq 5
    end

    it "passes the arguments to the continuation" do
      d = DescriptiveRecovery.new
      standin = proc{|*args|args}
      d.instance_eval{@continuation = standin}
      expect(d.invoke(5,6)).to eq [5,6]
    end
  end

  describe "#summary" do
    it "reports the class summary if unset" do
      expect(DescriptiveRecovery.new.summary).to eq "summary"
    end
    
    it "reports the overridden summary if set" do
      d = DescriptiveRecovery.new
      d.summary = "test"
      expect(d.summary).to eq "test"
    end
  end

  describe "#discussion" do
    it "reports the class discussion if unset" do
      expect(DescriptiveRecovery.new.discussion).to eq "discussion"
    end
    
    it "reports the overridden discussion if set" do
      d = DescriptiveRecovery.new
      d.discussion = "test"
      expect(d.discussion).to eq "test"
    end
  end
end
