require 'puppet/cloudpack'
require 'puppet/face/node_aws'

Puppet::Face.define :node_aws, '0.0.1' do
  action :fingerprint do
    summary 'Make a best effort to securely obtain the SSH host key fingerprint.'
    description <<-EOT
      This action attempts to retrieve a host key fingerprint by using the EC2
      API to search the console output. This provides a secure way to retrieve
      the fingerprint from an EC2 instance. You should run the `fingerprint`
      action immediately after creating an instance, as you wait for it to
      finish booting.

      This action can only retrieve a fingerprint if the instance's original
      image was configured to print the fingerprint to the system console.
      Note that many machine images do not print the fingerprint to the
      console. If this action is unable to find a fingerprint, it will display
      a warning.

      In either case, if this command returns without an error, then the
      instance being checked is ready for use.
    EOT

    arguments '<instance_name>'

    Puppet::CloudPack.add_fingerprint_options(self)
    when_invoked do |server, options|
      Puppet::CloudPack.fingerprint(server, options)
    end
  end
end

