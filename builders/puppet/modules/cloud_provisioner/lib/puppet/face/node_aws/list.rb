require 'puppet/cloudpack'
require 'puppet/face/node_aws'

Puppet::Face.define :node_aws, '0.0.1' do
  action :list do

    summary 'List AWS EC2 machine instances.'

    description <<-'EOT'
      This action obtains a list of instances from the cloud provider and
      displays them on the console output.  For EC2 instances, only the instances in
      a specific region are provided.
    EOT

    Puppet::CloudPack.add_list_options(self)

    when_invoked do |options|
      Puppet::CloudPack.list(options)
    end

    when_rendering :console do |value|
      value.collect do |id,status_hash|
        "#{id}:\n" + status_hash.collect do |field, val|
          "  #{field}: #{val}"
        end.sort.join("\n")
      end.sort.join("\n")
    end

    returns 'Array of attribute hashes containing information about each EC2 instance.'

    examples <<-'EOT'
      List every instance in the US East region:

          $ puppet node_aws list --region=us-east-1
          i-e8e04588:
            created_at: Tue Sep 13 01:21:16 UTC 2011
            dns_name: ec2-184-72-85-208.compute-1.amazonaws.com
            id: i-e8e04588
            state: running
    EOT

  end
end
