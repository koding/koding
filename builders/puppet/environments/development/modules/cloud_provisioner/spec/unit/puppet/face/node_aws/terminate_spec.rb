require 'spec_helper'
require 'puppet/cloudpack'

describe Puppet::Face[:node_aws, :current] do
  before :each do
    @options = {
      :platform => 'AWS'
    }
  end

  describe 'option validation' do
    describe '(platform)' do
      it 'should not require a platform' do
        @options.delete(:platform)
        # JJM This is absolutely not ideal, but I cannot for the life of me
        # figure out how to effectively deal with all of the create_connection
        # method calls in the option validation code.
        Puppet::CloudPack.stubs(:create_connection).with() do |options|
          raise(Exception, "#{options[:platform] == 'AWS'}")
        end
        expect { subject.terminate('server', @options) }.to raise_error Exception, 'true'
      end

      it 'should validate the platform' do
        @options[:platform] = 'UnsupportedProvider'
        expect { subject.terminate('server', @options) }.to raise_error ArgumentError, /one of/
      end
    end

    describe '(region)' do
      it "should set the region to us-east-1 if no region is supplied" do
        @options.delete(:region)
        # JJM This is absolutely not ideal, but I cannot for the life of me
        # figure out how to effectively deal with all of the create_connection
        # method calls in the option validation code.
        Puppet::CloudPack.stubs(:create_connection).with() do |options|
          raise(Exception, "region:#{options[:region]}")
        end
        expect { subject.terminate('server', @options) }.to raise_error Exception, 'region:us-east-1'
      end

      it 'should validate the region' do
        @options[:region] = 'mars-east-100'
        expect { subject.terminate('server', @options) }.to raise_error ArgumentError, /Unknown region/
      end
    end
  end
end
