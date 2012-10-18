require 'spec_helper'
require 'puppet/cloudpack'

describe Puppet::Face[:node_aws, :current] do
  before :all do
    data = Fog::Compute::AWS::Mock.data['us-east-1'][Fog.credentials[:aws_access_key_id]]
    data[:images]['ami-12345'] = { 'imageId' => 'ami-12345' }
    data[:key_pairs]['some_keypair'] = { 'keyName' => 'some_keypair' }
  end

  before :each do
    @options = {
      :platform => 'AWS',
      :image    => 'ami-12345',
      :type     => 'm1.small',
      :keyname  => 'some_keypair',
      :region   => 'us-east-1',
    }
  end

  describe 'option validation' do
    before :each do
      Puppet::CloudPack.expects(:create).never
    end

    describe '(platform)' do
      it 'should not require a platform' do
        @options.delete(:platform)
        # JJM This is absolutely not ideal, but I cannot for the life of me
        # figure out how to effectively deal with all of the create_connection
        # method calls in the option validation code.
        Puppet::CloudPack.stubs(:create_connection).with() do |options|
          raise(Exception, "#{options[:platform] == 'AWS'}")
        end
        expect { subject.create(@options) }.to raise_error Exception, 'true'
      end

      it 'should validate the platform' do
        @options[:platform] = 'UnsupportedProvider'
        expect { subject.create(@options) }.to raise_error ArgumentError, /one of/
      end
    end

    describe '(tags)' do
      let (:tags_hash) do { 'tag1' => 'value1', 'tag2' => 'value2', 'tag3' => 'value3.1=value3.2' }; end

      it 'should produce a hash correctly' do
        Puppet::CloudPack.expects(:create).with do |options|
          options[:tags] = tags_hash
        end
        subject.create(@options)
      end

      it 'should exit on improper value' do
        @options[:tags] = 'tag1=value2,tag2=value,=broken'
        expect { subject.create(@options) }.to raise_error ArgumentError, /could not parse/i
      end
    end

    describe '(type)' do
      it 'should require a type' do
        @options.delete(:type)
        expect { subject.create(@options) }.to raise_error ArgumentError, /required/
      end

      it 'should validate the type' do
        @options[:type] = 'UnsupportedType'
        expect { subject.create(@options) }.to raise_error ArgumentError, /one of/
      end
    end

    describe '(image)' do
      it 'should require an image' do
        @options.delete(:image)
        expect { subject.create(@options) }.to raise_error ArgumentError, /required/
      end

      it 'should validate the image name' do
        @options[:image] = 'RejectedImageName'
        expect { subject.create(@options) }.to raise_error ArgumentError,
          /unrecognized.*: #{@options[:image]}/i
      end
    end

    describe '(keyname)' do
      it 'should require a keyname' do
        @options.delete(:keyname)
        expect { subject.create(@options) }.to raise_error ArgumentError, /required/
      end

      it 'should validate the image name' do
        @options[:keyname] = 'RejectedKeypairName'
        expect { subject.create(@options) }.to raise_error ArgumentError,
          /unrecognized.*: #{@options[:keyname]}/i
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
        expect { subject.create(@options) }.to raise_error Exception, 'region:us-east-1'
      end

      it 'should validate the region' do
        @options[:region] = 'mars-east-100'
        expect { subject.create(@options) }.to raise_error ArgumentError, /Unknown region/
      end
    end
  end

  describe 'option validation with create() Mock' do
    describe '(security-group)' do
      it 'should call group_option_before_action' do
        @options[:group] = %w[ A B C D E ].join(File::PATH_SEPARATOR)
        # This makes sure the before_action calls the group_option_before_action
        # correctly with the options we've specified.
        # We raise the exception to prevent the call to the create() action
        # from happening.
        Puppet::CloudPack.stubs(:group_option_before_action).with() do |options|
          if options[:group] == @options[:group] then
            raise Exception, 'group_option_before_action called correctly'
          else
            raise Exception, 'group_option_before_action called incorrectly'
          end
        end
        expect { subject.create(@options) }.to raise_error Exception, /called correctly/
      end

      it 'should validate all group names' do
        @options[:group] = %w[ A B C ]
        expect { subject.create(@options) }.to raise_error ArgumentError,
          /unrecognized.*: #{@options[:group].join(', ')}/i
      end
    end
  end
end
