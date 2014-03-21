require 'spec_helper'

include Mulligan

describe Collector do
  it 'executes the expression passed to \'when\' only once' do
    times = 0
    exception = begin
      case recovery
      when begin
        times = times + 1
        IgnoringRecovery
      end
      else ; raise ; end
    rescue => e
      recover IgnoringRecovery
    end
    expect(times).to eq(1)
  end
end
