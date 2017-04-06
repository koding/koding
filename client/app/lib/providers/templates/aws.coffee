# AWS PROVIDER DEFAULT STACK TEMPLATE

module.exports =
  # JSON FORMAT
  json: '''
{
  "provider": {
    "aws": {
      "access_key": "${var.aws_access_key}",
      "secret_key": "${var.aws_secret_key}"
    }
  },
  "resource": {
    "aws_instance": {
      "aws-instance": {
        "tags": {
          "Name": "${var.koding_user_username}-${var.koding_group_slug}"
        },
        "instance_type": "${var.userInput_instance_type}",
        "ami": "",
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
  aws:
    access_key: '${var.aws_access_key}'
    secret_key: '${var.aws_secret_key}'
resource:
  aws_instance:
    # this is the name of your VM
    aws-instance:
      # select your instance_type here: eg. c3.xlarge
      instance_type: '${var.userInput_instance_type}'
      # select your ami (defaults to Ubuntu 14.04)
      ami: ''
      # we will tag the instance here so you can identify it when you login to your AWS console
      tags:
        Name: '${var.koding_user_username}-${var.koding_group_slug}'
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
      instance_type: 't2.nano'


### Full YAML Example

provider:
  aws:
    access_key: '${var.aws_access_key}'
    secret_key: '${var.aws_secret_key}'
  github:
    organizationKey: '${var.github_organization_access_token}'
    userKey: '${var.github_user_access_token}'
builders:
  - type: amazon-ebs
    access_key: '{{user `aws_access_key`}}'
    secret_key: '{{user `aws_secret_key`}}'
    ami_name: 'koding-base-latest-{{timestamp}}'
    ami_description: Koding Base Image
    instance_type: m3.medium
    region: ap-northeast-1
    source_ami: ami-9e5cff9e
    subnet_id: subnet-7e66e209
    vpc_id: vpc-ef17be8a
    ssh_username: ubuntu
    tags:
      Name: koding-test
  - type: virtualbox-iso
    disk_size: 40960
    guest_os_type: Ubuntu_64
    http_directory: http
    iso_checksum: 83aabd8dcf1e8f469f3c72fff2375195
    iso_checksum_type: md5
    iso_url: 'http://releases.ubuntu.com/14.04/ubuntu-14.04.2-server-amd64.iso'
    ssh_username: vagrant
    ssh_password: vagrant
    ssh_port: 22
    ssh_wait_timeout: 10000
    shutdown_command: "echo 'shutdown -P now' > /tmp/shutdown.sh; echo 'vagrant'|sudo -S sh '/tmp/shutdown.sh'"
    vboxmanage:
      - - modifyvm
        - '{{.Name}}'
        - '--memory'
        - '512'
      - - modifyvm
        - '{{.Name}}'
        - '--cpus'
        - '1'
provisioners:
  - type: shell
    inline:
      - 'echo ${var.github_adduser.adduser.publicKey} > ~/.ssh/id_rsa.pub'
      - 'echo ${var.github_adduser.adduser.privateKey} > ~/.ssh/id_rsa'
      - chmod 600 ~/.ssh/
      - 'git clone git@github.com:${var.github_username}/${lookup(var.github_reponames, 0)}.git'
      - 'git clone git@github.com:${var.github_username}/${lookup(var.github_reponames, 1)}.git'
resource:
  aws_instance:
    web:
      source_dest_check: false
      user_data: "\necho ${var.github_adduser.adduser.publicKey} > ~/.ssh/id_rsa.pub\n&& echo ${var.github_adduser.adduser.privateKey} > ~/.ssh/id_rsa\n&& chmod 600 ~/.ssh/*\n&& git clone git@github.com:${var.github_username}/${lookup(var.github_reponames, 0)}.git  \n&& git clone git@github.com:${var.github_username}/${lookup(var.github_reponames, 1)}.git \n&& cd folder \n&& make install"
  github_adduser:
    add:
      organizationKey: '${var.github_organization_access_token}'
      userKey: '${var.github_user_access_token}'
      username: '${var.github_username}'
      source_repos: '${var.github_reponames}'
  twitter_post:
    send:
      accessToken: '${var.twitter_access_token}'
      body: 'We are excited to announce @${var.koding_user_twitter_username} joined our team!1!!1!!1'
  koding_post:
    join_team:
      url: 'https://api.koding.com/integration/incoming/<integration id>'
      body: '@channel, please welcome ${var.koding_username} to team!'
  gmail_create_user:
    email:
      email: '${var.koding_username}@koding.com'
      notificationEmail: '${var.koding_user_contact_email}'
###
