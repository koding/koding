require 'spec_helper'
require 'puppet/cloudpack'
require 'puppet/cloudpack/utils'

module Fog
  module SSH
    class Mock
      def run(commands)
        commands.collect do |command|
          Result.new(command)
        end
      end
      class Result
        attr_accessor :command, :stderr, :stdout, :status
        def initialize(command)
          @command = command
          @stderr = command
          @stdout = command
        end
      end
    end
  end
  module SCP
    class Mock
      def upload(local_path, remote_path, upload_options = {})
        nil
      end
    end
  end
end

describe Puppet::CloudPack do
  before(:all) { @stdout, $stdout = $stdout, StringIO.new(@buffer = '') }
  after(:all)  { $stdout = @stdout }

  def server
    stub = Puppet::CloudPack.stubs(:create_server)
    stub.with do |servers, options|
      server = servers.create(options)
      stub.returns(server)
      yield server
    end
  end

  # The real kicker here is that we don't actually even *care* about the
  # console output; we care about the host's fingerprints.
  def stub_console_output(last_message=nil)
    server do |server|
      server.stubs(:console_output => mock do
        responses = [ nil, nil, nil, nil, nil, last_message ]
        responses.collect! { |output| { 'output' => output } }
        stubs(:body).returns(*responses)
      end)
    end
  end

  describe 'actions' do

    after(:each) { Fog::Compute::AWS::Mock.reset}

    describe '#create' do
      describe 'with valid arguments' do
        before :each do
          stub_console_output("pre\nec2: ####\nec2: PRINTS\nec2: ####\npost\n")
          @result = subject.create(:platform => 'AWS', :image => 'ami-12345')
          @server = Fog::Compute.new(:provider => 'AWS').servers.first
        end

        it 'should tag the newly created instance as created by us' do
          @server.tags.should include('Created-By' => 'Puppet')
        end

        it 'should create a new running instance' do
          @server.should be_ready
        end

        it 'should return the dns name of the new instance' do
          @result.should == @server.dns_name
        end

      end

      describe 'when tags are not supported' do
        it 'should not add any tags' do
          subject.create(
            :platform => 'AWS',
            :image => 'ami-12345',
            :tags_not_supported => true
          )
          Fog::Compute.new(:provider => 'AWS').servers.first.tags.should == {}
        end
      end

      describe 'in exceptional situations' do
        before(:all) { @options = { :platform => 'AWS', :image => 'ami-12345' } }

        subject { Puppet::CloudPack.create(@options) }

        describe 'like when creating the new instance fails' do
          before :each do
            server do |server|
              server.stubs(:ready?).raises(Fog::Errors::Error)
            end
          end

          it 'should explain what went wrong' do
            subject
            @logs.join.should match /Could not connect to host/
          end

          it 'should provide further instructions' do
            subject
            @logs.join.should match /check your network connection/
          end

          it 'should have a nil return value' do
            subject.should be_nil
          end
        end
        describe 'like when the created instance is in an error state' do
          before :each do
            server do |server|
              server.stubs(:state).returns('error')
            end
          end

          it 'should explain what went wrong' do
            subject
            @logs.join.should match /Launching machine instance \S+ Failed/
            @logs.join.should match /Instance has entered an error state/
          end

          it 'should return nil' do
            subject.should be_nil
          end
        end
      end
    end

    describe '#terminate' do
      describe 'with valid arguments' do
        before :each do
          @connection = Fog::Compute.new(:provider => 'AWS')
          @servers = @connection.servers
          @server = @servers.create(:image_id => '12345')

          Fog::Compute.stubs(:new => @connection)
          @connection.stubs(:servers => @servers)

          @server.wait_for(&:ready?)
        end

        subject { Puppet::CloudPack }

        it 'should destroy the specified instance' do
          args = { 'dns-name' => 'some.name' }
          @servers.expects(:all).with(args).returns([@server])
          @server.expects(:destroy)

          subject.terminate('some.name', { })
        end
        it 'should use the specified terminate id when filtering for nodes to terminate' do
          args = { 'instance-id' => 'some.name' }
          @servers.expects(:all).with(args).returns([@server])
          @server.expects(:destroy)

          subject.terminate('some.name', { :terminate_id => 'instance-id' })
        end
      end
    end

    describe '#list' do
      describe 'with valid arguments' do
        before :each do
          subject.create(:platform => 'AWS', :image => 'ami-12345')
          @result = subject.list(:platform => 'AWS')
        end
        it 'should not be empty' do
          @result.should_not be_empty
        end
        it "should look like a hash of identifiers" do
          @result.each do |k,v|
            k.should match(/^i-\w+/i)
          end
        end
        it "should be a kind of Hash" do
          @result.should be_a_kind_of(Hash)
        end
      end
    end

    describe '#fingerprint' do
      describe 'with valid arguments' do
        before :all do
          @connection = Fog::Compute.new(:provider => 'AWS')
          @servers = @connection.servers
          @server = @servers.create(:image_id => '12345')
          # Commented because without a way to mock the busy wait on the console output,
          # these tests take WAY too long.
          # @result = subject.fingerprint(@server.dns_name, :platform => 'AWS')
        end
        it 'should not be empty' do
          pending "Fog does not provide a mock Excon::Response instance with a non-nil body.  As a result we wait indefinitely in this test.  Pending a better way to test an instance with console output already available."
          result = subject.fingerprint(@server.dns_name, :platform => 'AWS')
          result.should_not be_empty
        end
        it "should look like a list of fingerprints" do
          pending "#8348 unimplemented (What does a valid fingerprint look like?)"
          result = subject.fingerprint(@server.dns_name, :platform => 'AWS')
          result.should_not be_empty
        end
        it "should be a kind of Array" do
          pending "#8348 We need a way to mock the busy loop wait on console output."
          @result.should be_a_kind_of(Hash)
        end
      end
    end
  end

  describe 'install helper methods' do
    let(:ssh_remote_execute_return_hash) { { :stdout => 'fakestdout', :exit_code => 0 } }

    before :all do
      @server = 'ec2-50-19-20-121.compute-1.amazonaws.com'
      @login  = 'root'
      @keyfile = Tempfile.open('private_key')
      @keydata = 'FOOBARBAZ'
      @keyfile.write(@keydata)
      @keyfile.close
    end
    before :each do
      @ssh_mock = Fog::SSH::Mock.new(@server, @login, 'options')
      @scp_mock = Fog::SCP::Mock.new('local', 'remote', {})
      @mock_connection_tuple = { :ssh => @ssh_mock, :scp => @scp_mock }
    end
    after :all do
      File.unlink(@keyfile.path)
    end
    describe '#install' do
      before :each do
        @options = {
          :keyfile           => @keyfile.path,
          :login             => @login,
          :server            => @server,
          :install_script    => "puppet-enterprise-http",
          :installer_answers => "/Users/jeff/vms/moduledev/enterprise/answers_cloudpack.txt",
        }
        Puppet::CloudPack.expects(:ssh_connect).with(@server, @login, @keyfile.path).returns(@mock_connection_tuple)
        Puppet::CloudPack.expects(:ssh_remote_execute).times(3).with(any_parameters).returns ssh_remote_execute_return_hash
      end
      it 'should return the specified certname' do
        subject.install(@server, @options)['status'].should == 'success'
      end
      it 'should set server as public_dns_name option' do
        subject.expects(:compile_template).with do |options|
          options[:public_dns_name] == @server
        end
        subject.install(@server, @options)
      end
    end
    describe '#install - setting up install command' do
      before :each do
        @options = {
          :keyfile           => @keyfile.path,
          :server            => @server,
        }
      end
      it 'should pre-pend sudo to command if login is not root' do
        @options[:login] = 'dan'
        @options[:install_script] = 'puppet-community'
        Puppet::CloudPack.expects(:ssh_connect).with(@server, 'dan', @keyfile.path).returns(@mock_connection_tuple)
        @is_command_valid = false
        @has_keyfile = true
        Puppet::CloudPack.expects(:ssh_remote_execute).times(3).with do |server, login, command, keyfile|
          if command =~ /^sudo bash -c 'chmod u\+x \S+puppet-community\.sh; \S+puppet-community\.sh'/
            # set that the command is valid when it matches the regex
            # the test will pass is this is set to true
            @is_command_valid = true
          end
          @has_keyfile = keyfile == @keyfile.path and @has_keyfile
          true
        end.returns(ssh_remote_execute_return_hash)
        subject.install(@server, @options)
        @is_command_valid.should be_true
        @has_keyfile.should be_true
      end
      it 'should not add sudo to command when login is root' do
        @options[:login] = 'root'
        @options[:install_script] = 'puppet-community'
        Puppet::CloudPack.expects(:ssh_connect).with(@server, 'root', @keyfile.path).returns(@mock_connection_tuple)
        @is_command_valid = false
        Puppet::CloudPack.expects(:ssh_remote_execute).times(3).with do |server, login, command, keyfile|
          if command =~ /^bash -c 'chmod u\+x \S+puppet-community\.sh; \S+puppet-community\.sh'/
            # set that the command is valid when it matches the regex
            # the test will pass is this is set to true
            @is_command_valid = true
          else
            # return true for all invocations of ssh_remote_execute
            true
          end
        end.returns({:exit_code => 0, :stdout => 'fakestdout'})
        result = subject.install(@server, @options)
        result['status'].should == 'success'
        result['puppetagent_certname'].should == 'fakestdout'
        @is_command_valid.should be_true
      end
    end
    describe '#init' do
      it 'should use the certname from install to classify and sign certificate' do
        options = {}
        dnsname = 'my_dnsname'
        puppetagent_certname = 'certname'
        face_mock = mock('Puppet::Indirector::Face')
        face_mock.expects(:sign).with(puppetagent_certname, {:ca_location => :remote})
        Puppet::Face.expects(:[]).with(:certificate, '0.0.1').returns(face_mock)
        subject.expects(:install).with(dnsname, options).returns(
          {
            'status'               => 'success',
            'puppetagent_certname' => puppetagent_certname,
          }
        )
        subject.expects(:classify).with(puppetagent_certname, options)
        subject.init(dnsname, options)
      end
    end
    describe '#classify' do
      it 'should not call dashboard_classify when node group is not set' do
        Puppet::CloudPack.expects(:dashbaord_classify).never
        Puppet.expects(:notice).with('No classification method selected')
        Puppet::CloudPack.classify('certname', :node_group => nil)
      end
    end
    describe '#dashboard_classify' do
      before :each do
        @http = mock('Net::Http')
        @http.expects('use_ssl=').with(false)
        @headers = { 'Content-Type' => 'application/json' }
      end
      def http_response_mock(stubbed_methods = {})
        stubbed_methods = {:code => '200', :message => "OK", :content_type => "application/json"}.merge(stubbed_methods)
        http_mock = mock('Net::HTTPResponse')
        http_mock.stubs(stubbed_methods)
        http_mock
      end
      let :ok_host_list do
        http_response_mock(:body => '[{"reported_at":null,"name":"certname", "id":"1" }]')
      end
      let :ok_group_list do
        http_response_mock(:body => '[{"name":"foo","id":"1"}]')
      end
      let :ok_add do
        http_response_mock(:code => '201', :body => '{"id":"1"}')
      end
      let :ok_member_list do
        http_response_mock(:body => '[{"node_group_id":"1", "node_id":"1"}]')
      end
      let :empty_list do
        http_response_mock(:body => '[]')
      end
      let :http_fail do
        http_response_mock(:code => '400', :body => '[]')
      end

      let :response_nodes_only_master do
        [{"name"=>"puppetmaster",
          "reported_at"=>"2011-11-03T05:35:36Z",
          "created_at"=>"2011-11-02T02:28:35Z",
          "last_apply_report_id"=>44,
          "updated_at"=>"2011-11-03T05:35:41Z",
          "url"=>nil,
          "id"=>1,
          "last_inspect_report_id"=>nil,
          "description"=>nil,
          "status"=>"unchanged",
          "hidden"=>false}]
      end

      let :response_nodes_already_exists do
        response_nodes_only_master << response_register_new_node
      end

      let :response_register_new_node do
        { "name"=>"certname",
          "reported_at"=>"2011-11-03T05:35:36Z",
          "created_at"=>"2011-11-03T01:27:44Z",
          "last_apply_report_id"=>45,
          "updated_at"=>"2011-11-03T05:35:41Z",
          "url"=>nil,
          "id"=>7,
          "last_inspect_report_id"=>nil,
          "description"=>nil,
          "status"=>"unchanged",
          "hidden"=>false }
      end

      let :response_node_groups do
        [{"name"=>"foo", "id"=>1}]
      end

      let :response_node_groups_does_not_exist do
        [{"name"=>"bar", "id"=>2}]
      end

      let :response_node_group_members_already_registered do
        [{"node_group_id"=>1, "node_id"=>7}]
      end
      let :response_node_group_members_not_registered do
        [{"node_group_id"=>1, "node_id"=>1}]
      end

      describe 'default options' do
        it 'should use the default enc options' do
          Puppet::Network::HttpPool.http_instance('puppet', 3000)
          Puppet::Network::HttpPool.expects(:http_instance).with('puppet', 3000).returns @http
          subject.expects(:http_request).with() do |http, path, options, action, expected_code, data|
            path == '/nodes.json' && action =~ /list nodes/i
          end.returns(response_nodes_only_master)
          subject.expects(:http_request).with() do |http, path, options, action, expected_code, data|
            path == '/nodes.json' && action =~ /register node/i && data
          end.returns(response_register_new_node) # <= This is the key expectation
          subject.expects(:http_request).with() do |http, path, options, action, expected_code, data|
            path == '/node_groups.json' && action =~ /list groups/i
          end.returns(response_node_groups)
          subject.expects(:http_request).with() do |http, path, options, action, expected_code, data|
            path == '/memberships.json' && action =~ /list group members/i
          end.returns(response_node_group_members_already_registered)
          Puppet::Face[:node, :current].classify('certname', :node_group => 'foo')
        end
      end
      describe 'non default options' do
        before :each do
          @options = { :node_group => 'foo', :enc_server => 'server', :enc_port => '3000' }
          Puppet::Network::HttpPool.expects(:http_instance).with('server', '3000').returns @http
        end
        it 'should create a node if it does not already exist in Dashboard' do
          subject.expects(:http_request).with() do |http, path, options, action, expected_code, data|
            path == '/nodes.json' && action =~ /list nodes/i
          end.returns(response_nodes_only_master)
          subject.expects(:http_request).with() do |http, path, options, action, expected_code, data|
            path == '/nodes.json' && action =~ /register node/i && data
          end.returns(response_register_new_node) # <= This is the key expectation
          subject.expects(:http_request).with() do |http, path, options, action, expected_code, data|
            path == '/node_groups.json' && action =~ /list groups/i
          end.returns(response_node_groups)
          subject.expects(:http_request).with() do |http, path, options, action, expected_code, data|
            path == '/memberships.json' && action =~ /list group members/i
          end.returns(response_node_group_members_already_registered)
          subject.classify('certname', @options)
        end

        it 'should not create the node if it already exists in Dashboard' do
          subject.expects(:http_request).with() do |http, path, options, action, expected_code, data|
            path == '/nodes.json' && action =~ /list nodes/i
          end.returns(response_nodes_already_exists)
          subject.expects(:http_request).with() do |http, path, options, action, expected_code, data|
            path == '/nodes.json' && action =~ /register node/i && data
          end.never # <= This is the key expectation
          subject.expects(:http_request).with() do |http, path, options, action, expected_code, data|
            path == '/node_groups.json' && action =~ /list groups/i
          end.returns(response_node_groups)
          subject.expects(:http_request).with() do |http, path, options, action, expected_code, data|
            path == '/memberships.json' && action =~ /list group members/i
          end.returns(response_node_group_members_already_registered)
          subject.classify('certname', @options)
        end
        it 'should not add the node group to the node if it had already been added' do
          subject.expects(:http_request).with() do |http, path, options, action, expected_code, data|
            path == '/nodes.json' && action =~ /list nodes/i
          end.returns(response_nodes_already_exists)
          subject.expects(:http_request).with() do |http, path, options, action, expected_code, data|
            path == '/node_groups.json' && action =~ /list groups/i
          end.returns(response_node_groups)
          subject.expects(:http_request).with() do |http, path, options, action, expected_code, data|
            path == '/memberships.json' && action =~ /list group members/i
          end.returns(response_node_group_members_already_registered)
          subject.expects(:http_request).with() do |http, path, options, action, expected_code, data|
            path == '/memberships.json' && action =~ /Classify node/i
          end.never # <= This is the key expectation
          subject.classify('certname', @options)
        end
        it 'should add the node group to the node if it was not already added' do
          subject.expects(:http_request).with() do |http, path, options, action, expected_code, data|
            path == '/nodes.json' && action =~ /list nodes/i
          end.returns(response_nodes_already_exists)
          subject.expects(:http_request).with() do |http, path, options, action, expected_code, data|
            path == '/node_groups.json' && action =~ /list groups/i
          end.returns(response_node_groups)
          subject.expects(:http_request).with() do |http, path, options, action, expected_code, data|
            path == '/memberships.json' && action =~ /list group members/i
          end.returns(response_node_group_members_not_registered)
          subject.expects(:http_request).with() do |http, path, options, action, expected_code, data|
            path == '/memberships.json' && action =~ /Classify node/i
          end # <= This is the key expectation
          subject.classify('certname', @options)
        end
        it 'should fail when it cannot find the node group in the dashboard' do
          subject.expects(:http_request).with() do |http, path, options, action, expected_code, data|
            path == '/nodes.json' && action =~ /list nodes/i
          end.returns(response_nodes_already_exists)
          subject.expects(:http_request).with() do |http, path, options, action, expected_code, data|
            path == '/node_groups.json' && action =~ /list groups/i
          end.returns(response_node_groups_does_not_exist)
          expect { subject.classify('certname', @options) }.should raise_error(Puppet::Error, /Groups must exist before they can be assigned to nodes/)
        end
      end
    end
    describe '#handle_json_response' do
      let :http_fail do
        http_mock = mock('Net::HTTPResponse')
        http_mock.stubs(:code => '400', :body => '[]')
        http_mock
      end
      it 'should fail on unexpected http response codes' do
        expect { Puppet::CloudPack.handle_json_response(http_fail, 'Action', expected_code='200') }.should raise_error(Puppet::Error, /Could not: Action/)
      end
    end
    describe '#ssh_connect' do
      before :each do
        Puppet::CloudPack.expects(:ssh_test_connect).with(@server, @login, @keyfile.path).returns(true)
      end
      it 'should return Fog::SSH and Fog::SCP instances' do
        Fog::SSH.expects(:new).with(@server, @login, {:key_data => [@keydata]}).returns(@ssh_mock)
        Fog::SCP.expects(:new).with(@server, @login, {:key_data => [@keydata]}).returns(@scp_mock)
        results = subject.ssh_connect(@server, @login, @keyfile.path)
        results[:ssh].should be @ssh_mock
        results[:scp].should be @scp_mock
      end
    end
    describe '#ssh_test_connect' do
      before :each do
        subject.stubs(:sleep)
      end
      describe "with transient failures" do
        it 'should be tolerant of ??? failures' do
          pending 'Dan mentioned specific conditions which are unknown at this time.'
        end
        describe 'with Net:SSH::AuthenticationFailed failures' do
          it 'should be tolerant of intermittent failures' do
            Puppet::CloudPack.stubs(:ssh_remote_execute).raises(Net::SSH::AuthenticationFailed, 'root').then.returns(true)
            subject.ssh_test_connect('server', 'root', @keyfile.path)
          end
          it 'should fail eventually' do
            pending "JJM: (#10172) This timeout causes the tests to run WAY too slow.  We need to mock this better.  This test also appears to be in the wrong describe block"
            Puppet::CloudPack.stubs(:ssh_remote_execute).raises(Net::SSH::AuthenticationFailed, 'root')
            expect { subject.ssh_test_connect('server', 'root', @keyfile.path) }.should raise_error(Puppet::CloudPack::Utils::RetryException::Timeout)
          end
        end
      end
      describe 'with general Exception failures' do
        it 'should not be tolerant of intermittent errors' do
          Puppet::CloudPack.stubs(:ssh_remote_execute).raises(Exception, 'some error').then.returns(true)
          expect { subject.ssh_test_connect('server', 'root', @keyfile.path) }.should raise_error(Exception, 'some error')
        end
        it 'should fail eventually ' do
          Puppet::CloudPack.stubs(:ssh_remote_execute).raises(Exception, 'some error')
          expect { subject.ssh_test_connect('server', 'root', @keyfile.path) }.should raise_error(Exception, 'some error')
        end
      end
    end
    describe '#upload_payloads' do
      it 'should not upload anything if nothing is specifed to upload' do
        @scp_mock.expects(:upload).never
        @result = subject.upload_payloads(
          @scp_mock,
          {}
        )
      end
      it 'should upload answers file when specified' do
        @scp_mock.expects(:upload).with('foo', "/tmp/puppet.answers")
        @result = subject.upload_payloads(
          @scp_mock,
          {:installer_answers => 'foo', :tmp_dir => '/tmp'}
        )
      end
      it 'should upload installer_payload when specified' do
        @scp_mock.expects(:upload).with('foo', "/tmp/puppet.tar.gz")
        @result = subject.upload_payloads(
          @scp_mock,
          {:installer_payload => 'foo', :tmp_dir => '/tmp'}
        )
      end
      ['http://foo:80', 'ftp://foo', 'https://blah'].each do |url|
        it 'should not upload the installer_payload when it is an http URL' do
          @scp_mock.expects(:upload).never
          @result = subject.upload_payloads(
            @scp_mock,
            {:installer_payload => url, :tmp_dir => '/tmp'}
          )
        end
      end
      it 'should require installer payload when install-script is puppet-enterprise' do
        expect do
          subject.upload_payloads(
            @scp_mock,
            :install_script => 'puppet-enterprise',
            :installer_answers => 'foo'
          )
        end.should raise_error Exception, /Must specify installer payload/
      end
      it 'should require installer answers when install-script is puppet-enterprise' do
        expect do
          subject.upload_payloads(
            @scp_mock,
            :install_script => 'puppet-enterprise',
            :installer_payload => 'foo'
          )
        end.should raise_error Exception, /Must specify .*? answers file/
      end
    end
    describe '#compile_template' do
      it 'should be able to compile a template' do
        tmp_file = begin
          tmp = Tempfile.open('foo')
          tmp.write('Here is a <%= options[:variable] %>')
          tmp.path
        ensure
          tmp.close
        end
        tmp_filename = File.basename(tmp_file)
        tmp_basedir = File.join(File.dirname(tmp_file), 'scripts')
        tmp_file_real = File.join(tmp_basedir, "#{tmp_filename}.erb")
        FileUtils.mkdir_p(tmp_basedir)
        FileUtils.mv(tmp_file, tmp_file_real)
        Puppet[:confdir] = File.dirname(tmp_file)
        @result = subject.compile_template(
          :variable => 'variable',
          :install_script => tmp_filename
        )
        File.read(@result).should == 'Here is a variable'
      end
    end
  end

  describe 'helper functions' do
    before :each do
      @login   = 'root'
      @server  = 'ec2-75-101-189-165.compute-1.amazonaws.com'
      @keyfile = Tempfile.open('private_key')
      @keydata = 'FOOBARBAZ'
      @keyfile.write(@keydata)
      @keyfile.close
      @options = {
        :keyfile           => @keyfile.path,
        :login             => @login,
        :server            => @server,
        :install_script    => "puppet-enterprise-s3",
        :installer_answers => "/Users/jeff/vms/moduledev/enterprise/answers_cloudpack.txt",
      }
    end

    describe '#create_connection' do
      it 'should create a new connection' do
        Fog::Compute.expects(:new).with(:provider => 'SomeProvider')
        subject.send :create_connection, :platform => 'SomeProvider'
      end

      it 'should create a connection with region when the provider is aws and region is set' do
        Fog::Compute.expects(:new).with(:provider => 'AWS', :region => 'us-east-1', :endpoint => nil)
        subject.send :create_connection, :platform => 'AWS', :region => 'us-east-1'
      end

      it 'should create a connection with region and endpoint when the provider is aws and region and endpoint are set' do
        Fog::Compute.expects(:new).with(
          :provider => 'AWS',
          :region => 'us-east-1',
          :endpoint => 'http://172.21.0.19:8773/services/Cloud'
        )
        subject.send(:create_connection,
          :platform => 'AWS',
          :region => 'us-east-1',
          :endpoint => 'http://172.21.0.19:8773/services/Cloud'
        )
      end

      it 'should use auxiliary credentials' do
        Fog.expects(:credential=).with(:SomeCredential)
        Fog::Compute.expects(:new).with(:provider => 'SomeProvider')
        subject.send :create_connection,
          :platform    => 'SomeProvider',
          :credentials => 'SomeCredential'
      end
    end

    describe '#create_server' do
      it 'should create a new server' do
        options = { :image_id => 'ami-12345' }
        servers = mock { expects(:create).with(options) }
        subject.send :create_server, servers, options
      end
    end

    describe '#create_tags' do
      it 'should create new tags for the given server' do
        tags = mock do
          expects(:create).with(
            :key         => 'Created-By',
            :value       => 'Puppet',
            :resource_id => 'i-1234'
          )
        end
        subject.send :create_tags, tags, 'i-1234', {'Created-By' => 'Puppet'}
      end
    end

    describe '#http_request' do
      let :http do
        http = mock('Net::Http')
        http.expects(:start).returns(http_response)
        http
      end
      let :http_post do
        http = mock('Net::Http')
        http.expects(:start).with() do
        end
      end
      let :options do
        { :enc_server=>"puppetmaster", :enc_port=>"3000" }
      end
      let :options_ssl_auth do
        options.merge({ :enc_ssl=>true, :enc_auth_user=>"console", :enc_auth_passwd=>"puppet"})
      end
      let :http_response do
        stub_everything('Net::HTTPOK')
      end
      let :request do
        request = mock('Net::Http::Post')
        request.expects(:set_content_type).with('application/json')
        request
      end
      let :somedata do
        { 'node' => { 'name' => 'puppetagent.certname' } }
      end
      # http_request(http, path, options = {}, action = nil, expected_code = '200', data = nil)
      it 'Should default to expecting a 200 response' do
        subject.expects(:handle_json_response).with(http_response, '/foo.json', '200')
        subject.http_request(http, '/foo.json', options)
      end
      it 'Should return whatever handle_json_response() returns' do
        subject.expects(:handle_json_response).with(http_response, '/foo.json', '200').returns('OK')
        subject.http_request(http, '/foo.json', options).should eq 'OK'
      end
      it 'Should support an action description' do
        subject.expects(:handle_json_response).with(http_response, 'Get Foo', '200')
        subject.http_request(http, '/foo.json', options, 'Get Foo')
      end
      it 'Should support HTTP codes other than 200' do
        subject.expects(:handle_json_response).with(http_response, 'Get Foo', '201')
        subject.http_request(http, '/foo.json', options, 'Get Foo', '201')
      end
      it 'Should set the request body when data is provided' do
        Net::HTTP::Post.expects(:new).returns(request)
        request.expects(:body=).with(somedata.to_pson)
        subject.expects(:handle_json_response).with(http_response, 'Post Foo', '201')
        subject.http_request(http, '/foo.json', options, 'Post Foo', '201', somedata)
      end
      it 'Should set authentication data when --enc-auth-user is not nil and data is provided' do
        Net::HTTP::Post.expects(:new).returns(request)
        request.expects(:body=).with(somedata.to_pson)
        request.expects(:basic_auth).with(options_ssl_auth[:enc_auth_user], options_ssl_auth[:enc_auth_passwd])
        subject.expects(:handle_json_response).with(http_response, 'Post Foo', '201')
        subject.http_request(http, '/foo.json', options_ssl_auth, 'Post Foo', '201', somedata)
      end
      it 'Should set authentication data when --enc-auth-user is not nil and data is not provided' do
        Net::HTTP::Get.expects(:new).returns(request)
        request.expects(:basic_auth).with(options_ssl_auth[:enc_auth_user], options_ssl_auth[:enc_auth_passwd])
        subject.expects(:handle_json_response).with(http_response, 'Post Foo', '201')
        subject.http_request(http, '/foo.json', options_ssl_auth, 'Post Foo', '201')
      end
    end
  end

  describe 'option parsing helper functions' do
    before :each do
      @options = {
        :platform => 'AWS',
        :image    => 'ami-12345',
        :type     => 'm1.small',
        :keypair  => 'some_keypair',
        :region   => 'us-east-1',
      }
    end
    it 'should split a group string on the path separator' do
      @options[:group] = %w[ A B C D E ].join(File::PATH_SEPARATOR)
      Puppet::CloudPack.stubs(:create_connection).with() do |options|
        if options[:group] == %w[ A B C D E ] then
          raise Exception, 'group was split as expected'
        else
          raise Exception, 'group was not split as expected'
        end
      end
      expect { Puppet::CloudPack.group_option_before_action(@options) }.to raise_error Exception, /was split as expected/
    end

  end
end
