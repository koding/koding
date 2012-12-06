require 'puppet/face/node_aws'
require 'puppet/cloudpack'

Puppet::Face.define :node_aws, '0.0.1' do
  action :list_keynames do

    summary 'List available AWS EC2 key names.'

    description <<-'EOT'
      This action lists the available AWS EC2 key names and their fingerprints.
      Any key name from this list is a valid argument for the create action's
      --keyname option.
    EOT

    Puppet::CloudPack.add_list_keynames_options(self)

    when_invoked do |options|
      Puppet::CloudPack.list_keynames(options)
    end

    when_rendering :console do |value|
      value.collect do |key_hash|
        "#{key_hash['name']} (#{key_hash['fingerprint']})"
      end.sort.join("\n")
    end

    returns 'Array of attribute hashes containing information about each key pair'

    examples <<-'EOT'
      List the available key pairs:

          $ puppet node_aws list_keynames
          cody (58:c6:4f:3e:b5:51:e0:ec:49:55:4e:98:43:8f:28:f3:9a:14:c8:a3)
          jeff (6e:b6:0a:27:5b:67:cd:8b:47:74:9c:f7:b2:b0:b9:ab:3a:25:d0:28)
          matt (4b:8c:8d:a9:e5:88:6a:47:b7:8b:97:c5:77:e7:b7:6f:fd:b9:64:b3)

      Get the key pair list as an array of JSON hashes:

          $ puppet node_aws list_keynames --render-as json
          [{"name":"cody","fingerprint":"58:c6:4f:3e:b5:51:e0:ec:49:55:4e:98:43:8f:28:f3:9a:14:c8:a3"},
           {"name":"jeff","fingerprint":"6e:b6:0a:27:5b:67:cd:8b:47:74:9c:f7:b2:b0:b9:ab:3a:25:d0:28"},
           {"name":"matt","fingerprint":"4b:8c:8d:a9:e5:88:6a:47:b7:8b:97:c5:77:e7:b7:6f:fd:b9:64:b3"}]
    EOT

  end
end
