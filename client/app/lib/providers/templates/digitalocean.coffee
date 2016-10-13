# DIGITALOCEAN PROVIDER DEFAULT STACK TEMPLATE

module.exports =
  # JSON FORMAT
  json: '''
{
  "provider": {
    "digitalocean": {
      "token": "${var.do_token}"
    }
  },
  "resource": {
    "digitalocean_droplet": {
      "example-instance": {
        "name": "example-instance",
        "size": "512mb",
        "region": "nyc2",
        "image": "ubuntu-14-04-x64",
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
    token: '${var.do_token}'

resource:
  digitalocean_droplet:
    # this is the name of your VM
    example-instance:
      # and this is its identifier (required)
      name: example-instance
      # select your instance_type here: eg. 512mb
      size: 512mb
      # select your instance zone which must be in provided region: eg. nyc2
      region: nyc2
      # base image for your droplet
      image: ubuntu-14-04-x64
      # on user_data section we will write bash and configure our VM
      user_data: |-
        # let's create a file on your root folder:
        echo "hello world!" >> /helloworld.txt
        # please note: all commands under user_data will be run as root.
        # now add your credentials and save this stack.
        # once vm finishes building, you can see this file by typing
        # ls /
        #
        # for more information please click the link below "Stack Script Docs"

    '''
