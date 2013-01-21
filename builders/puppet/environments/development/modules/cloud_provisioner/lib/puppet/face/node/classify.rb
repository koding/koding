require 'puppet/cloudpack'

Puppet::Face.define :node, '0.0.1' do
  action :classify do
    summary 'Add a node to a console or Dashboard group.'
    description <<-EOT
      Add node <certname> to a group in Puppet Dashboard, Puppet Enterprise's
      console, or any external node classifier that provides a similar API.

      Classification of a node will allow it to receive proper configurations
      on its next Puppet run. This action assumes that you have already
      created a console or Dashboard group with the classes the node should
      receive in its configuration catalog.

      This action can be used on both physical and virtual machines, and can
      be run multiple times for a single node. This action can be safely run
      before the `install` action.
    EOT
    examples <<-'EOEXAMPLE'
      Add the agent01.example.com node to the pe_agents group:

          puppet node classify \
            --enc-server puppetmaster.example.com \
            --enc-port 3000 \
            --enc-ssl \
            --node-group pe_agents \
            agent01.example.com
    EOEXAMPLE

    arguments '<certname>'

    when_rendering :console do |return_value|
      return_value['status'] || 'OK'
    end

    Puppet::CloudPack.add_classify_options(self)
    when_invoked do |certname, options|
      Puppet::CloudPack.classify(certname, options)
    end
  end
end
