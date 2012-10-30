require 'spec_helper'
require 'puppet/cloudpack'

describe Puppet::Face[:node, :current] do
  let(:options) do
    { :node_group => 'webserver' }
  end

  describe 'option validation' do
    let(:expected_options) do
      {
        :node_group => 'webserver',
        :extra => {},
        :enc_server => 'puppet',
        :enc_port => 3000,
        :enc_auth_user => nil,
        :enc_auth_passwd => nil,
      }
    end

    describe '(node-group)' do
      it 'should not call dashboard_classify if node_group is not supplied' do
        options.delete(:node_group)
        subject.expects(:dashboard_classify).never
        subject.classify('server', options)
      end
      it 'should call dashboard_classify if a node_group is specified' do
        Puppet::CloudPack.expects(:dashboard_classify).with('server', expected_options).once
        subject.classify('server', options)
      end

      it 'should accept the --enc-ssl option' do
        options[:enc_ssl] = true
        expected_options.merge!(options)
        Puppet::CloudPack.expects(:dashboard_classify).with('agent_cn', expected_options).once
        subject.classify('agent_cn', options)
      end
    end
  end
end
