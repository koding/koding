# SOFTLAYER PROVIDER DEFAULT STACK TEMPLATE

module.exports =

  # JSON
  json: '''
{
  "provider": {
    "softlayer": {
      "username": "${var.softlayer_username}",
      "api_key": "${var.softlayer_api_key}"
    }
  },
  "resource": {
    "softlayer_virtual_guest": {
      "softlayer-vg": {
        "name": "softlayer-vg",
        "domain": "koding.com",
        "ssh_keys": ["${softlayer_ssh_key.koding_ssh_key.id}"],
        "machine_type": "t2.micro",
        "image": "UBUNTU-14-64",
        "region": "dal09",
        "public_network_speed": 10,
        "cpu": 1,
        "ram": 1024
      }
    }
  }
}
  '''

  # YAML
  yaml: '''
# Here is your stack preview
# You can make advanced changes like modifying your VM,
# installing packages, and running shell commands.

provider:
  softlayer:
    username: '${var.softlayer_username}'
    api_key: '${var.softlayer_api_key}'

resource:
  softlayer_virtual_guest:
    # this is the name of your VM
    softlayer_vg:
      # and this is its identifier (required)
      name: softlayer_vg
      domain: koding.com
      ssh_keys:
        - "${softlayer_ssh_key.koding_ssh_key.id}"
      # select your instance_type here: eg. n1-standard-1
      machine_type: t2.micro
      # base image for your instance
      image: UBUNTU-14-64
      # select your region which must be in provided region: eg. dal09
      region: dal09
      public_network_speed: 10
      cpu: 1
      ram: 1024
      metadata:
        # on user_data section we will write bash and configure our VM
        user-data: |-
          # let's create a file on your root folder:
          echo "hello world!" >> /helloworld.txt
          # please note: all commands under user_data will be run as root.
          # now add your credentials and save this stack.
          # once vm finishes building, you can see this file by typing
          # ls /
          #
          # for more information please click the link below "Stack Script Docs"
  '''
