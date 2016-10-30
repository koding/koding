# AZURE PROVIDER DEFAULT STACK TEMPLATE

module.exports =
  # JSON FORMAT
  json: '''
{
  "provider": {
    "azure": {
      "publish_settings": "${var.azure_publish_settings}",
      "subscription_id": "${var.azure_subscription_id}"
    }
  },
  "resource": {
    "azure_instance": {
      "azure-instance": {
        "size": "Basic_A1",
        "image": "Ubuntu Server 14.04 LTS",
        "custom_data": "\\necho \\\"hello world!\\\" >> /helloworld.txt\\n"
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
  azure:
    publish_settings: '${var.azure_publish_settings}'
    subscription_id: '${var.azure_subscription_id}'

resource:
  azure_instance:
    # this is the name of your VM
    azure-instance:
      # select your instance size here: eg. Basic_A1
      size: Basic_A1
      # base image for your instance
      image: 'Ubuntu Server 14.04 LTS'
      # on custom_data section we will write bash and configure our VM
      custom_data: |-
        # let's create a file on your root folder:
        echo "hello world!" >> /helloworld.txt
        # please note: all commands under user_data will be run as root.
        # now add your credentials and save this stack.
        # once vm finishes building, you can see this file by typing
        # ls /
        #
        # for more information please click the link below "Stack Script Docs"

    '''
