# SOFTLAYER PROVIDER DEFAULT STACK TEMPLATE

module.exports =

  # JSON
  json: '''
{
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

resource:
  softlayer_virtual_guest:
    # this is the name of your VM
    softlayer_vg:
      # and this is its identifier (required)
      name: softlayer_vg
      domain: koding.com
      # base image for your instance
      image: UBUNTU-14-64
      # select your region which must be in provided region: eg. dal09
      region: dal09
      public_network_speed: 10
      cpu: 1
      ram: 1024
      local_disk: true
      hourly_billing: true
  '''
