module.exports =
  stackTemplate: """
    # Here is your stack preview
    # You can make advanced changes like modifying your VM,
    # installing packages, and running shell commands.

    provider:
      aws:
        access_key: '${var.aws_access_key}'
        secret_key: '${var.aws_secret_key}'
    resource:
      aws_instance:
        example:
          tags:
            Name: '${var.koding_user_username}-${var.koding_group_slug}'
          instance_type: t2.nano
          ami: ''
          user_data: |
            echo ${var.userInput_username}
            echo ${var.userInput_password}
    """

  multiMachineStackTemplate: """
    # Here is your stack preview
    # You can make advanced changes like modifying your VM,
    # installing packages, and running shell commands.

    provider:
      aws:
        access_key: '${var.aws_access_key}'
        secret_key: '${var.aws_secret_key}'
    resource:
      aws_instance:
        example:
          tags:
            Name: '${var.koding_user_username}-${var.koding_group_slug}'
          instance_type: t2.nano
          ami: ''
          user_data: |
            echo ${var.userInput_username}
            echo ${var.userInput_password}
        mexample:
          tags:
            Name: '${var.koding_user_username}-${var.koding_group_slug}'
          instance_type: t2.nano
          ami: ''
    """

  readme: '''
    ### Test stack readme

    This is the readme for my stack template.
    To learn about stack files [click here](https://koding.com/docs/creating-an-aws-stack).
  '''
