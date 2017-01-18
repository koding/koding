# GOOGLE PROVIDER DEFAULT STACK TEMPLATE

module.exports =
  # JSON FORMAT
  json: '''
{
  "provider": {
    "google": {
      "credentials": "${var.google_credentials}",
      "project": "${var.google_project}",
      "region": "${var.google_region}"
    }
  },
  "resource": {
    "google_compute_instance": {
      "google-instance": {
        "name": "koding-${var.koding_group_slug}-${var.koding_stack_id}-${count.index+1}",
        "machine_type": "${var.userInput_machine_type}",
        "disk": {
          "image": "${var.userInput_image}"
        },
        "zone": "${var.userInput_zone}",
        "metadata": {
          "user-data": "\\necho \\\"hello world!\\\" >> /helloworld.txt\\n"
        }
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
  google:
    credentials: '${var.google_credentials}'
    project: '${var.google_project}'
    region: '${var.google_region}'

resource:
  google_compute_instance:
    # this is the name of your VM
    google-instance:
      # and this is its identifier (required)
      name: 'koding-${var.koding_group_slug}-${var.koding_stack_id}-${count.index+1}'
      # select your instance_type here: eg. n1-standard-1
      machine_type: '${var.userInput_machine_type}'
      # base image for your instance
      disk:
        image: '${var.userInput_image}'
      # select your instance zone which must be in provided region: eg. us-central1-a
      zone: '${var.userInput_zone}'
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
          # for more information please use the search box above

    '''

  # Defaults
  defaults:
    userInputs:
      zone: 'us-central1-a'
      image: 'ubuntu-1404-lts'
      machine_type: 'f1-micro'
