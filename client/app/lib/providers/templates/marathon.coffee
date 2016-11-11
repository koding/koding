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
        "cmd": "python3 -m http.server 8080",
        "container": {
          "docker": [
            {
              "image": "python:3",
              "network": "BRIDGE"
            }
          ]
        },
        "cpus": 1.2,
        "mem": 256
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
    url: "${var.marathon_url}"
    basic_auth_user: "${var.marathon_basic_auth_user}"
    basic_auth_password: "${var.marathon_basic_auth_password}"

resource:
  marathon_app:
    # this is the name of your app
    app:
      # entry point command for your app
      cmd: python3 -m http.server 8080

      # base container for this app
      container:
        docker:
        - image: python:3
          network: BRIDGE

      # define your container specs here, 1.2 cpus, 256MB of memory etc.
      cpus: 1.2
      mem: 256
'''
