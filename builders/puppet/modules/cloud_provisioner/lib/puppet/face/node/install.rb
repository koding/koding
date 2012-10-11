require 'puppet/cloudpack'

Puppet::Face.define :node, '0.0.1' do
  action :install do
    summary 'Install Puppet on a running node.'
    description <<-EOT
      Installs Puppet on an existing node at <hostname_or_ip>. It uses scp to
      copy installation requirements to the machine, and ssh to run the
      installation commands remotely.

      This action can be used on both physical and virtual machines.
    EOT

    arguments '<hostname_or_ip>'

    Puppet::CloudPack.add_install_options(self)
    when_rendering :console do |return_value|
      return_value.keys.sort.collect { |k| "%20.20s: %-20s" % [k, return_value[k]] }.join("\n")
    end
    when_invoked do |server, options|
      Puppet::CloudPack.install(server, options)
    end
  end
end
