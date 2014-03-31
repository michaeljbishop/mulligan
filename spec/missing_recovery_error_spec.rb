$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'mulligan'
require "mulligan/error/missing_recovery"


describe MissingRecoveryError do
  it "has the previous choice" do
    begin
      mg_raise
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
      mg_raise "test"
    rescue => previous
      begin
        recover RetryingRecovery
        rescue MissingRecoveryError => e
          expect(e.cause).to eq(previous)
      end
    end
  end

  it "allows executing with new args" do
    result = begin
    case r = recovery
    when ContinuingRecovery
      r.argv
    else
      mg_raise "test"
    end
    rescue RuntimeError => previous
      begin
        recover RetryingRecovery
        rescue MissingRecoveryError => e
          recover RetryingRecovery, ContinuingRecovery, 5, 6
      end
      [7,8]
    end
    expect(result).to eq Mulligan.supported? ? [5,6] : [7,8]
  end
end

