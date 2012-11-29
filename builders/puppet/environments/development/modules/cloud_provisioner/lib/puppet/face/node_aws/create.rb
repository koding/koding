require 'puppet/cloudpack'
require 'puppet/face/node_aws'

Puppet::Face.define :node_aws, '0.0.1' do
  action :create do
    summary 'Create a new EC2 machine instance.'
    description <<-EOT
      This action launches a new Amazon EC2 instance and returns the public
      DNS name suitable for SSH access.

      A newly created system may not be immediately ready after launch while
      it boots. You can use the `fingerprint` action to wait for the system to
      become ready after launch.

      If creation of the instance fails, Puppet will automatically clean up
      after itself and tear down the instance.
    EOT
    Puppet::CloudPack.add_create_options(self)
    when_invoked do |options|
      Puppet::CloudPack.create(options)
    end
  end
end
