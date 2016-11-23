# SOFTLAYER PROVIDER DEFAULT STACK TEMPLATE

module.exports =

  # JSON
  json: '''
{
  "provider": {
    "softlayer": {
      "username": "softlayer_username",
      "api_key": "${var.softlayer_api_key}"
    }
  },

  "resource": {
    "softlayer_virtual_guest": {
      "softlayer-vg": {
        "name": "softlayer-vg",
        "domain": "koding.com",
        "region": "dal09",
        "ssh_keys": ["123456"],
        "image": "UBUNTU_14_64",
        "cpu": 1,
        "ram": 1024,
        "local_disk": true,
        "public_network_speed": 10,
        "hourly_billing": true
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
    softlayer_vg:
      name: softlayer-vg
      domain: koding.com

      # Extra keypairs to be added to the new instance.
      # ssh_keys:
      #  - 123456

      # One of available SoftLayer regions
      region: dal09

      # Default image is Ubuntu 14.04 LTS x64
      # image: UBUNTU_14_64

      cpu: 1
      ram: 1024
      local_disk: true
      public_network_speed: 10

      hourly_billing: true

  '''
