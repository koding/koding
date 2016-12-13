---
layout: doc
title: Create an AWS stack
permalink: /docs/creating-an-aws-stack
parent: /docs/home
---

# {{ page.title }}

## Introduction

**Stacks** allows you to configure the number of servers and applications to install on each of the VMs. Your new team members will be able to use your stack to build their Koding VMs and start working from day one.

## Step by step guide

1. Click '+' sign to **Create a New Stack**

    ![Create new stack][1]

2. Choose **Amazon Web Services** and click **Create Stack**

    ![Choose AWS provider][2]

3. You will now see the default stack template for AWS. You can give your stack a name by clicking on the **Edit Name** on top beside your stack title. The _three tabs_ represent:

    1.  **Stack template**: configuration file for your development environment
    2.  **Custom variables**: define custom variables to use in your stack template, hidden from Team _members_
    3.  **Readme**: This text will be shown in a message box when your team starts to build this stack. You can add instructions or notes for your team to read
    4.  **Credentials**: add your AWS account credentials here

    ![Stack template][3]

    Review the **Stack Template** file to add/modify/remove any of your VM configurations

    >You can add commands to run once your VM starts under the **user_data** section. For example you can choose to install services/packages once a VM starts. Commands under the **user_data** section will run as `root` when the VM boots.

    >Click away from any of the tabs to return to your **Stack template editor**.

4.  Edit your **Readme** section to greet your team and provide them with information or instructions

    ![Read Me][4]

7.  Go to the **Credentials** tab and click **Add New Credentials**

    ![Credentials][5]

8.  For this step you will need to have your Amazon AWS **Access Key ID** & **Secret Access Key**. You can generate and acquire yours from your AWS account.

    > If you do not have an AWS account yet, please create one on Amazon AWS here [aws.amazon.com](http://aws.amazon.com).
    >
    > After you login:
    > - Make sure you subscribe to EC2 service on AWS **Console**
    > - Click **Services** _(top left)_ **-> EC2** 
    > - To generate your Credentials keys _follow first **5 steps**_ at the bottom of this [AWS guide][6] .

    ## Add your AWS Credentials
    > If you followed AWS recommended tip on creating an IAM user rather than using your AWS root user account to generate the crednetials, you need to make sure your new IAM user has enough privileges to create EC2's. Please follow our [Setup AWS IAM user](/docs/setup-aws-iam-user) guide to know which roles should be assigned for this user in order to use the credentials and build your stack successfully.

    - **Title**: add a name to your key pairs, _the title is a name for your reference it can be any name you want make it something easy to remember your credentials with._ 
    - **Access Key ID**: your AWS access key id
    - **Secret Access Key**: your AWS secret access key id
    - **Region**: the physical location where you want your VMs to be created.

    When you are done please click **Save**.

    ![step011.png]({{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/step011.png)

9. Click **USE THIS & CONTINUE** to use your AWS keys, you should see your key highlighted with "**IN USE**" if all went well. You can also **show** and **delete** your AWS keys when you hover your mouse over your AWS key.

    ![step012_2.png]({{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/step012_2.png "step8.png")

10. You will be directed to the Stack Template section. Click **SAVE** to save your stack and test your stack configuration file

    ![step013.png]({{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/step013.png "step9_success.png")

11. Click on **Build Stack** and your new Stack will start building..

    ![step014.png]({{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/step014.png "step12_buildstackready.png")

    Stack building..

    ![step014_2.png]({{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/step014_2.png)

12. Congratulations, your Stack was successfully built and you can now use your new VM

    ![step015.png]({{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/step015.png)

## Advanced notes for creating an AWS Stack

This is an example stack script the defines the **drive size** which you can use with your AWS Stack:

```yaml
# Here is your stack preview
# You can make advanced changes like modifying your VM,
# installing packages, and running shell commands.

provider:
  aws:
    access_key: "${var.aws_access_key}"
    secret_key: "${var.aws_secret_key}"
resource:
  aws_instance:
  # this is the name of your VM
    my_instance_name:
      # select your instance_type here: eg. c3.xlarge
      instance_type: t2.micro
      # customize details about the root block device of the instance
      root_block_device:
        # define the size of the volume in gigabytes
        volume_size: 12
      user_data: |-
        df -h
```

> **Tip**
> See more options and information for creating an AWS instance here [AWS_INSTANCE](/docs/aws_instance).

[1]: {{ site.url }}/assets/img/guides/create-new-stack.png
[2]: {{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/aws-provider.png
[3]: {{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/aws-create-stack.png
[4]: {{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/aws-readme.png
[5]: {{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/aws-credentials.png
[6]: http://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html
