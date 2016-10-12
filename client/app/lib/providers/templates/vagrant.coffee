# VAGRANT PROVIDER DEFAULT STACK TEMPLATE

module.exports =
  # JSON FORMAT
  json: '''
{
  "resource": {
    "vagrant_instance": {
      "localvm": {
        "cpus": 2,
        "memory": 2048,
        "box": "ubuntu/trusty64",
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

resource:
  vagrant_instance:
    # this is the name of your VM
    localvm:
      # define your vm specs here, 2 cpus, 2GB of memory etc.
      cpus: 2
      memory: 2048
      # select your image (optional) eg. ubuntu/trusty64 (it should be based on ubuntu 14.04)
      box: ubuntu/trusty64
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
