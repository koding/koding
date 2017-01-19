# VAGRANT PROVIDER DEFAULT STACK TEMPLATE

module.exports =
  # JSON FORMAT
  json: '''
{
  "provider": {
    "marathon": {
      "url": "${var.marathon_url}",
      "basic_auth_user": "${var.marathon_basic_auth_user}",
      "basic_auth_password": "${var.marathon_basic_auth_password}"
    }
  },
  "resource": {
    "marathon_app": {
      "app": {
        "container": {
          "docker": [
            {
              "image": "${var.userInput_image}",
              "network": "BRIDGE"
            }
          ]
        },
        "instances": 1,
        "cpus": "${var.userInput_cpus}",
        "mem": "${var.userInput_mem}"
      }
    }
  }
}
'''

  # YAML FORMAT WITH COMMENTS
  yaml: '''
# Here is your stack preview
# You can make advanced changes like modifying your Container,
# using different commands or containers etc.

provider:
  marathon:
    url: '${var.marathon_url}'
    basic_auth_user: '${var.marathon_basic_auth_user}'
    basic_auth_password: '${var.marathon_basic_auth_password}'

resource:
  marathon_app:
    # this is the name of your app
    app:
      # this is a list of containers running within your app
      container:
        docker:
        - image: '${var.userInput_image}'
          network: BRIDGE

      # number of my-app instances
      instances: 1

      # define your container specs here, 1.0 cpus, 256MB of memory etc.
      cpus: '${var.userInput_cpus}'
      mem: '${var.userInput_mem}'
'''

  # Defaults
  defaults:
    userInputs:
      image: 'ubuntu:14.04'
      cpus: 1.0
      mem: 256
