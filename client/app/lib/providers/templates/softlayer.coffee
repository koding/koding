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
      "softlayer-instance": {
        "name": "softlayer-instance",
        "domain": "koding.com",
        "region": "${var.userInput_region}",
        "image": "${var.userInput_image}",
        "cpu": "${var.userInput_cpu}",
        "ram": "${var.userInput_ram}",
        "local_disk": true,
        "public_network_speed": 10,
        "hourly_billing": true,
        "user_data": "\\necho \\\"hello world!\\\" >> /helloworld.txt\\n"
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
    softlayer-instance:
      name: softlayer-instance
      domain: koding.com

      # Extra keypairs to be added to the new instance.
      # ssh_keys:
      #  - 123456

      # One of available SoftLayer regions
      region: '${var.userInput_region}'

      # Default image is Ubuntu 14.04 LTS x64
      image: '${var.userInput_image}'

      cpu: '${var.userInput_cpu}'
      ram: '${var.userInput_ram}'
      local_disk: true
      public_network_speed: 10

      hourly_billing: true

      # on user_data section we will write bash and configure our VM
      user_data: |-
        # let's create a file on your root folder:
        echo "hello world!" >> /helloworld.txt
        # please note: all commands under user_data will be run as root.
        # now add your credentials and save this stack.
        # once vm finishes building, you can see this file by typing
        # ls /
        #
        # for more information please use the search box above

  '''

  # Defaults
  defaults:
    userInputs:
      region: 'dal09'
      image: 'UBUNTU_14_64'
      cpu: 1
      ram: 1024
