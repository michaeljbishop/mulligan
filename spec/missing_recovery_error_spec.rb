$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'mulligan'
require "mulligan/missing_recovery_error"


describe MissingRecoveryError do
  it "has the previous choice" do
    begin
      raise
    rescue
      begin
        recover RetryingRecovery
        rescue MissingRecoveryError => e
          expect(e.chosen_recovery).to be(RetryingRecovery)
      end
    end
  end

  it "has the previous error" do
    begin
      raise "test"
    rescue => previous
      begin
        recover RetryingRecovery
        rescue MissingRecoveryError => e
          expect(e.cause).to eq(previous)
      end
    end
  end
end

