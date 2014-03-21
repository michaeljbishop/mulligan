require 'spec_helper'

include Mulligan

class RootRecovery < Recovery
end
 
class ReturningAllParametersRecovery < Recovery
  attr_reader :arguments
  def initialize(*args)
    @arguments = args
  end
end
 
class SubclassRecovery < RootRecovery
end
 
describe Mulligan do
  it 'should have a version number' do
    Mulligan::VERSION.should_not be_nil
  end
end
