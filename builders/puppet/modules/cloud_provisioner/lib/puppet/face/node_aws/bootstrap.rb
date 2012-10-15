require 'puppet/cloudpack'
require 'puppet/face/node_aws'

Puppet::Face.define :node_aws, '0.0.1' do
  action :bootstrap do
    summary 'Create and initialize an EC2 instance using Puppet.'
    description <<-EOT
      Creates an instance, classifies it, and signs its certificate. The
      classification is currently done using Puppet Dashboard or Puppet
      Enterprise's console.
    EOT
    Puppet::CloudPack.add_bootstrap_options(self)
    when_invoked do |options|
      Puppet::CloudPack.bootstrap(options)
    end
  end
end
