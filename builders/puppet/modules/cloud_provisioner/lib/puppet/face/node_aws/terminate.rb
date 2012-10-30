require 'puppet/cloudpack'
require 'puppet/face/node_aws'

Puppet::Face.define :node_aws, '0.0.1' do
  action :terminate do
    summary 'Terminate an EC2 machine instance.'
    description <<-EOT
      Terminate the instance identified by <instance_name>.
    EOT

    arguments '<instance_name>'

    Puppet::CloudPack.add_terminate_options(self)
    when_invoked do |server, options|
      Puppet::CloudPack.terminate(server, options)
    end
  end
end
