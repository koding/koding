require 'puppet/cloudpack'

Puppet::Face.define :node, '0.0.1' do
  action :init do
    summary 'Install Puppet on a node and classify it.'
    description <<-EOT
      Installs Puppet on an arbitrary node (see "install"), classify it in
      Puppet Dashboard or Puppet Enterprise's console (see "classify"), and
      automatically sign its certificate request (using the `certificate`
      face's `sign` action).
    EOT
    Puppet::CloudPack.add_init_options(self)
    when_invoked do |server, options|
      Puppet::CloudPack.init(server, options)
    end
  end
end
