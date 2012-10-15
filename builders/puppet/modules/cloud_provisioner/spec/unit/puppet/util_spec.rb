require 'spec_helper'
require 'puppet/cloudpack/utils'


describe Puppet::CloudPack::Utils do
  describe 'retry_action' do
  
    before(:each) do
      @retry_exceptions = {
        ArgumentError => "Wrong number of arguments.",
        IOError       => "Something went wrong with IO"
      }
      @start = Time.now
    end
    
    context "when a timeout and no retry_exceptions are given" do
      it "should require a block" do
        expect {Puppet::CloudPack::Utils.retry_action(:timeout => 0.1)}.to
        raise_error(Puppet::CloudPack::Utils::RetryException::NoBlockGiven)
      end
      
       it "should timeout" do
        expect do
          Puppet::CloudPack::Utils.retry_action(:timeout => 0.1) do
            raise
          end
        end.to raise_error(Puppet::CloudPack::Utils::RetryException::Timeout)
      end
    end
    
    context "when retry_exceptions and no timeout are given" do
      it "should raise RetryException::NoTimeoutGiven" do
        expect do
          Puppet::CloudPack::Utils.retry_action(:retry_exceptions => @retry_exceptions) do
            raise Exception
          end
        end.to raise_error(Puppet::CloudPack::Utils::RetryException::NoTimeoutGiven)
      end
    end

    context "when an exception list and a timeout is given" do
      it "should retry the action for a time period no shorter than the timeout" do
        timeout = 5
        expect do
          Puppet::CloudPack::Utils.retry_action(
            :timeout          => timeout,
            :retry_exceptions => @retry_exceptions) do
              raise ArgumentError
          end
        end.to raise_error(Puppet::CloudPack::Utils::RetryException::Timeout)
        runtime = (Time.now - @start)
        runtime.should >= timeout
      end
      
      it "should retry the action for a time period no longer than the timeout plus action run time" do
        timeout = 5
        expect do
          Puppet::CloudPack::Utils.retry_action(
            :timeout          => timeout,
            :retry_exceptions => @retry_exceptions) do
              raise ArgumentError
          end
        end.to raise_error(Puppet::CloudPack::Utils::RetryException::Timeout)
        max_runtime = timeout + 1
        runtime = (Time.now - @start)
        
        runtime.should < max_runtime
      end
    end
    
    context "when no arguments are given" do
      it "should require a block" do
        expect {Puppet::CloudPack::Utils.retry_action}.to
        raise_error(Puppet::CloudPack::Utils::RetryException::NoBlockGiven)
      end
    
      it "should require a timeout" do
        expect do
          Puppet::CloudPack::Utils.retry_action do
            raise Exception
          end
        end.to raise_error(Puppet::CloudPack::Utils::RetryException::NoTimeoutGiven)
      end
    end
  end
end