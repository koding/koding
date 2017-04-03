# VAGRANT PROVIDER DEFAULT STACK TEMPLATE

module.exports =
  # JSON FORMAT
  json: '''
{
  "resource": {
    "vagrant_instance": {
      "vagrant-instance": {
        "cpus": "${var.userInput_cpus}",
        "memory": "${var.userInput_memory}",
        "box": "${var.userInput_box}",
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
    vagrant-instance:
      # define your vm specs here, 2 cpus, 2GB of memory etc.
      cpus: '${var.userInput_cpus}'
      memory: '${var.userInput_memory}'
      # select your image (defaults to ubuntu/trusty64)
      box: '${var.userInput_box}'
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
      memory: 2048
      cpus: 2
      box: 'ubuntu/trusty64'
