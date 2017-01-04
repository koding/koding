md = require 'app/util/applyMarkdown'

module.exports =

  variables : md '''
    You can define your custom variables, and use them in your stack template.
    **These variables will not be visible to your non-admins.**
    This is a YAML file, you can define a key-value pair like this here;

      `foo: bar`

    and you can use that variable in your stack template as below;

      `${var.custom_foo}`

    Using custom variables is useful in case you have some credentials that you do not wish to share with everyone. Variables in the custom variables section are used while the stack is building, but can not be seen by the users using your stack.

    To use the credentials, keys, or any important values you added to your Custom Variables tab, you use the below syntax. Remember that your Custom Variables are saved in key-value pairs. We use the KEY name preceded by ${var.custom_

    That means our variable will look like this: `${var.custom_**KEY-NAME**}`

  '''

  stack: md """

    ## What is Stack?

    Stack file/template is where you describe your dev environment using **[Terraform](https://www.terraform.io/docs/index.html). Koding** supports everything **Terraform** supports.

    Terraform is used by 100s of companies worldwide and it is used to create, manage, and manipulate infrastructure resources. Examples of resources include physical machines, VMs, network switches, containers, etc. Almost any infrastructure noun can be represented as a resource in Terraform.

    Terraform is agnostic to the underlying platforms by supporting providers. A provider is responsible for understanding API interactions and exposing resources. Providers generally are an IaaS (e.g. AWS, GCP, Microsoft Azure, OpenStack), PaaS (e.g. Heroku) or SaaS services (e.g. Atlas, DNSimple, CloudFlare).

    Koding Stacks are written in YAML format, here is [how to convert Terraform script to YAML](https://www.koding.com/docs/terraform-to-koding). It is very easy. We are planning to support Terraform files directly in the near future.

    **Koding Stack** is simply your development environment. This includes the VM(s) you need, the installed packages & tools on each VM and the network configuration you wish to setup (_ex: Virtual Private Cloud_).

    Your **Stack** can be a [simple single VM ](https://www.koding.com/docs/creating-an-aws-stack)where all your code is, it can be more than a VM, for example here is a [Stack for an Apache webserver VM & MySQL VM](https://www.koding.com/docs/two-vm-setup-apachephp-server-db-server). It can be a one or more VMs with ready setup packages and integration with _**third parties**_, here is a [GitHub single VM Stack](https://www.koding.com/docs/using-github-in-stacks) also check out this [Docker VM Stack](https://www.koding.com/docs/stack-for-docker)

    An example of a Stack file in YAML format:

    ```yaml
    # Basic stack template with one t2.nano on AWS provider

    provider:
      aws:
        access_key: '${var.aws_access_key}'
        secret_key: '${var.aws_secret_key}'
    resource:
      aws_instance:
        example-instance:
          instance_type: t2.nano
          tags:
            Name: '${var.koding_user_username}-${var.koding_group_slug}'
          user_data: |-
            # your custom script
            echo "hello world!" >> /helloworld.txt
    ```

  """

  readme: md '''

    You can write a readme for this stack template here.

    It will be displayed whenever a user attempts to build this stack.

    You can use markdown within the readme content.

  '''
