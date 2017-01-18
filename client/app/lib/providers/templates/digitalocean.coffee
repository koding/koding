# DIGITALOCEAN PROVIDER DEFAULT STACK TEMPLATE

module.exports =
  # JSON FORMAT
  json: '''
{
  "provider": {
    "digitalocean": {
      "access_token": "${var.digitalocean_access_token}"
    }
  },
  "resource": {
    "digitalocean_droplet": {
      "do-instance": {
        "name": "koding-${var.koding_group_slug}-${var.koding_stack_id}-${count.index+1}",
        "size": "${var.userInput_size}",
        "region": "${var.userInput_region}",
        "image": "${var.userInput_image}",
        "user_data": "\\necho \\\"hello world!\\\" >> /helloworld.txt\\n"
      }
    }
  }
}
    '''

  # YAML FORMAT WITH COMMENTS
  yaml: '''
# Here is your stack preview
# You can make advanced changes like modifying your VM,
# installing packages, and running shell commands.

provider:
  digitalocean:
    access_token: '${var.digitalocean_access_token}'

resource:
  digitalocean_droplet:
    # this is the name of your VM
    do-instance:
      # and this is its identifier (required)
      name: 'koding-${var.koding_group_slug}-${var.koding_stack_id}-${count.index+1}'
      # select your instance_type here: eg. 512mb
      size: '${var.userInput_size}'
      # select your instance zone which must be in provided region: eg. nyc2
      region: '${var.userInput_region}'
      # base image for your droplet
      image: '${var.userInput_image}'
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
      size: '512mb'
      image: 'ubuntu-14-04-x64'
      region: 'nyc2'
