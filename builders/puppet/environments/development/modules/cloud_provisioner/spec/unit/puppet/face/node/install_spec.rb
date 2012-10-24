require 'spec_helper'
require 'puppet/cloudpack'
require 'tempfile'

describe Puppet::Face[:node, :current] do
  before :each do
    @keyfile = Tempfile.new('file_on_disk.txt')
    @installer_payload = Tempfile.new('some.tar.gz')
    @installer_answers = Tempfile.new('some.answers')
    @options = {
      :login             => 'ubuntu',
      :keyfile           => @keyfile.path,
      :installer_payload => @installer_payload.path,
      :installer_answers => @installer_answers.path,
      :facts             => 'fact1=value1,fact2=value2,fact3=value3.1=value3.2'
    }
    ENV['SSH_AUTH_SOCK'] = '/tmp/foo.socket'
  end

  after :each do
    File.delete(@options[:keyfile])           if test 'f', @options[:keyfile]
    File.delete(@options[:installer_payload]) if test 'f', @options[:installer_payload]
    File.delete(@options[:installer_answers]) if test 'f', @options[:installer_answers]
  end

  describe 'option validation' do
    before :each do
      Puppet::CloudPack.expects(:install).never
    end

    describe '(login)' do
      it 'should require a login' do
        @options.delete(:login)
        expect { subject.install('server', @options) }.to raise_error ArgumentError, /required/
      end
    end

    describe '(keyfile)' do
      it 'should require a keyfile' do
        (opts = @options.dup).delete :keyfile
        expect { subject.install('server', opts) }.to raise_error ArgumentError, /required/
      end

      it 'should validate the keyfile name for existence' do
        opts = @options.update :keyfile => '/dev/null/nonexistent.file'
        expect { subject.install('server', opts) }.to raise_error ArgumentError, /could not find/i
      end

      it 'should validate the keyfile name for readability' do
        File.chmod 0300, @options[:keyfile]
        expect { subject.install('server', @options) }.to raise_error ArgumentError, /could not read/i
      end
    end

    describe '(install-script)' do
      it 'should default to community-edition' do
        Puppet::CloudPack.expects(:install).with do |server, options|
          options[:install_script] == 'puppet-community'
        end
        subject.install('server', @options)
      end
      it 'should be possible to set install-script' do
        Puppet::CloudPack.expects(:install).with do |server, options|
          options[:install_script] == 'puppet-enterprise'
        end
        subject.install('server', @options.merge(:install_script => 'puppet-enterprise'))
      end
    end

    describe '(facts)' do
      let(:facts_hash) do { 'fact1' => 'value1', 'fact2' => 'value2', 'fact3' => 'value3.1=value3.2' }; end

      it 'should produce a hash correctly' do
        Puppet::CloudPack.expects(:install).with do |server,options|
          options[:facts] == facts_hash
        end
        subject.install('server', @options)
      end

      it 'should exit on improper value' do
        @options[:facts] = 'fact1=value1,fact2=val,ue2,fact3=value3.1=value3.2'
        expect { subject.install('server', @options) }.to raise_error ArgumentError, /could not parse/i 
      end
    end

    describe '(installer-payload)' do
      it 'should validate the installer payload for existence' do
        opts = @options.update :installer_payload => '/dev/null/nonexistent.file'
        expect { subject.install('server', opts) }.to raise_error ArgumentError, /could not find/i
      end
      ['http://foo:8080', 'https://bar', 'ftp://baz'].each do |url|
        it "should not validate the installer payload for file existance when it is a url: #{url}" do
          Puppet::CloudPack.expects(:install)
          opts = @options.update :installer_payload => url
          subject.install('server', opts)
        end
      end
      it 'should detect invalid urls' do
        opts = @options.update :installer_payload => 'invalid path'
        expect { subject.install('server', opts) }.to raise_error ArgumentError, /Invalid input/
      end

      it 'should validate the installer payload for readability' do
        File.chmod 0300, @options[:installer_payload]
        expect { subject.install('server', @options) }.to raise_error ArgumentError, /could not read/i
      end

      it 'should warn if the payload does not have either tgz or gz extension' do
        @options[:installer_payload] = Tempfile.new('foo.tar').path
        Puppet.expects(:warning).with("Option: intaller-payload expects a .tgz or .gz file")
        Puppet::CloudPack.expects(:install)
        subject.install('server', @options)
      end
    end

    describe '(installer-answers)' do
      it 'should validate the answers file for existence' do
        opts = @options.update :installer_answers => '/dev/null/nonexistent.file'
        expect { subject.install('server', opts) }.to raise_error ArgumentError, /could not find/i
      end

      it 'should validate the answers file for readability' do
        File.chmod 0300, @options[:installer_answers]
        expect { subject.install('server', @options) }.to raise_error ArgumentError, /could not read/i
      end

      it 'should require an answers file if the script starts with puppet-enterprise-' do
        pending "The validation happens inside the install action, so this doesn't work because the install action is being mocked"
        opts = @options.dup
        opts.delete(:installer_payload)
        opts.delete(:installer_answers)
        opts[:installer_script] = "puppet-enterprise-s3"
        expect { subject.install('server', opts) }.to raise_error ArgumentError, /answers/i
      end
    end

    describe '(puppet-version)' do
      ['2.7.x', 'master', '2.6.9'].each do |version|
        it "should accept valid value #{version}" do
          opts = @options.update :puppet_version => version
          opts[:puppet_version].should == version
          Puppet::CloudPack.expects(:install)
          subject.install('server', @options)
        end
      end
      it 'should fail when invalid versions are specified' do
        opts = @options.update :puppet_version => '1.2.3.4'
        expect { subject.install('server', opts) }.to raise_error(ArgumentError, /Invaid Puppet version/)
      end
    end
  end

  describe 'when installing as root and non-root' do
    let(:ssh_remote_execute_results) do { :exit_code => 0, :stdout => 'stdout' }; end
    let(:root_options) do { :login => 'root', :keyfile => 'agent' }; end
    let(:user_options) do { :login => 'ubuntu', :keyfile => 'agent' }; end
    it 'should use sudo when not root' do
      # We (may) need a state machine here
      installation = states('installation').starts_as('unstarted')
      Puppet::CloudPack.expects(:ssh_remote_execute).returns(ssh_remote_execute_results).when(installation.is('unstarted')).then(installation.is('date_checked'))
      Puppet::CloudPack.expects(:ssh_remote_execute).returns(ssh_remote_execute_results).when(installation.is('date_checked')).then(installation.is('installed'))
      Puppet::CloudPack.expects(:ssh_remote_execute).returns(ssh_remote_execute_results).when(installation.is('installed')).then(installation.is('finished'))
      Puppet::CloudPack.expects(:ssh_remote_execute).returns(ssh_remote_execute_results).with("server", user_options[:login], 'sudo puppet agent --configprint certname', nil).when(installation.is('finished'))

      subject.install('server', user_options)
    end
    it 'should not use sudo when root' do
      # We (may) need a state machine here
      installation = states('installation').starts_as('unstarted')
      Puppet::CloudPack.expects(:ssh_remote_execute).returns(ssh_remote_execute_results).when(installation.is('unstarted')).then(installation.is('date_checked'))
      Puppet::CloudPack.expects(:ssh_remote_execute).returns(ssh_remote_execute_results).when(installation.is('date_checked')).then(installation.is('installed'))
      Puppet::CloudPack.expects(:ssh_remote_execute).returns(ssh_remote_execute_results).when(installation.is('installed')).then(installation.is('finished'))
      Puppet::CloudPack.expects(:ssh_remote_execute).returns(ssh_remote_execute_results).with("server", root_options[:login], 'puppet agent --configprint certname', nil).when(installation.is('finished'))

      subject.install('server', root_options)
    end
  end

  describe 'valid options' do
    describe 'keyfile option' do
      let(:user_options) do { :login => 'ubuntu', :keyfile => 'agent' }; end
      let(:ssh_remote_execute_results) do { :exit_code => 0, :stdout => 'stdout' }; end

      it 'should support using keys from an agent' do
        Puppet::CloudPack.expects(:install).once.with() do |server, received_options|
          received_options[:keyfile] == user_options[:keyfile]
        end
        subject.install('server', user_options)
      end

      it 'should not pass the string agent to ssh' do
        Puppet::CloudPack.expects(:ssh_remote_execute).times(4).with() do |server, login, command, keyfile|
          keyfile.should be_nil
        end.returns(ssh_remote_execute_results)
        subject.install('server', user_options)
      end

      it 'should raise an error if SSH_AUTH_SOCK is not set' do
        ENV['SSH_AUTH_SOCK'] = nil
        expect { subject.install('server', user_options) }.to raise_error ArgumentError, /SSH_AUTH_SOCK/
      end
    end

    describe 'puppetagent-certname option' do
      let(:user_options) do { :login => 'ubuntu', :keyfile => 'agent', :puppetagent_certname => 'jeffmaster' }; end

      it 'should support setting the agent certificate name' do
        Puppet::CloudPack.expects(:install).once.with() do |server, received_options|
          received_options[:puppetagent_certname] == user_options[:puppetagent_certname]
        end
        subject.install('server', user_options)
      end
    end
  end
end
