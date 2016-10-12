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
      "example-instance": {
        "name": "example-instance",
        "machine_type": "f1-micro",
        "zone": "us-central1-a",
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
  google:
    credentials: '${var.google_credentials}'
    project: '${var.google_project}'
    region: '${var.google_region}'

resource:
  google_compute_instance:
    # this is the name of your VM
    example-instance:
      # and this is its identifier (required)
      name: example-instance
      # select your instance_type here: eg. n1-standard-1
      machine_type: f1-micro
      # select your instance zone which must be in provided region: eg. us-central1-a
      zone: us-central1-a
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
