---
layout: doc
title: Create an AWS stack
permalink: /docs/creating-an-aws-stack
parent: /docs/home
---

# {{ page.title }}

## Introduction

This guide will help you build an AWS stack. [Amazon Web Services (AWS)](aws.amazon.com) offers a suite of cloud-computing services that make up an on-demand computing platform in several geographically distributed data centers.

You can configure the number of VMs and applications installed on each VM instance. Along with configuring VM size and region. Your new team members will be able to use your stack to build their VMs environment and start working from day one.

## Step by step guide

1. Click **Stacks**

    ![Click Stacks][1]

1. Click **New Stack**

    ![Click new stack][16]

2. Choose **Amazon Web Services** and click **Create Stack**

    ![Choose AWS provider][2]

3. You will now see the default stack template for AWS. You can give your stack a name by clicking on the **Edit Name** on top beside your stack title. The _three tabs_ represent:

    1.  **Custom variables**: define custom variables to use in your stack template, hidden from Team _members_
    2.  **Readme**: this text will be shown in a message box when your team starts to build this stack. You can add instructions or notes for your team to read
    3.  **Credentials**: add your AWS account credentials here

    ![Stack template][3]

    Review the **Stack Template** file to add/modify/remove any of your VM configurations

    >You can add commands to run once your VM starts under the **user_data** section. For example you can choose to install services/packages once a VM starts. Commands under the **user_data** section will run as `root` when the VM boots.

    >Click on the stack name to return to your **Stack template editor**.

4.  Edit your **Readme** section to greet your team and provide them with information or instructions. You can use [markdown](https://en.wikipedia.org/wiki/Markdown) format

    ![Read Me][4]

5.  Go to the **Credentials** tab and click **Add A New Credentials**

    ![Credentials][5]

6.  For this step you will need to have your Amazon AWS **Access Key ID** & **Secret Access Key**. You can generate and acquire yours from your AWS account

    > If you do not have an AWS account yet, please create one on Amazon AWS here [aws.amazon.com](http://aws.amazon.com). After you login:
    >
    > - Make sure you subscribe to EC2 service on AWS **Console**
    > - Click **Services** _(top left)_ **-> EC2** 
    > - To generate your Credentials keys _follow first **5 steps**_ at the bottom of this [AWS guide][6] .

    ## Add your AWS Credentials
    > If you followed AWS recommended tip on creating an IAM user rather than using your AWS root user account to generate the crednetials, you need to make sure your new IAM user has enough privileges to create EC2's. Please follow our [Setup AWS IAM user](/docs/setup-aws-iam-user) guide to know which roles should be assigned for this user in order to use the credentials and build your stack successfully.

    - **Title**: add a name to your key pairs, _the title is a name for your reference it can be any name you want make it something easy to remember your credentials with._ 
    - **Access Key ID**: your AWS access key id
    - **Secret Access Key**: your AWS secret access key id
    - **Region**: the data center location where you want your VMs to be created in

    When you are done please click **Save This & Continue**.

    ![Credentials details][7]

7. Your AWS credentials will be **verified** and you will be directed back to the Stack Template editor. Also the red exclamation mark that used to appear beside your **Credentials** tab should disappear. Click **SAVE** to save your stack and test your stack template file, it should save successfully

    ![Save Stack][8]

8. Click **Initialize** to initialize your stack

    > You can have multiple stacks within a team, click **Make Team Default** when you want to make this stack your team's default stack.

   ![Initialize Stack][9]

9. The build stack modal will appear, the *Instructions* tab will include the message you wrote in your **Read Me** tab. Click **Next** to continue

   ![Build Stack Instructions][10]

10. Click on **Build Stack** to start building your Stack

    > You can have multiple saved credentials to use within a team, the Credentials tab in your Build stack modal allows you to choose the one you want to use with this stack template.

    ![Build Stack Credentials][11]

    Your stack will start building..

    ![Stack Building][12]

11. Your stack was successfully built. Click **Start Coding** to start using your new VM

    ![Stack built][13]

    Congratulations, you can now start working on your new VM

    ![VM ready][14]


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

> See more options and information for creating an AWS instance here [AWS_INSTANCE][15].

[1]: {{ site.url }}/assets/img/guides/azure/click-stacks.png
[16]: {{ site.url }}/assets/img/guides/azure/click-new-stack.png
[2]: {{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/aws-provider.png
[3]: {{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/aws-default-stack.png
[4]: {{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/aws-readme.png
[5]: {{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/aws-credentials.png
[6]: http://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html
[7]: {{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/aws-credentials-add-new.png
[8]: {{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/aws-credentials-added.png
[9]: {{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/aws-save-stack.png
[10]: {{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/aws-build-stack-1.png
[11]: {{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/aws-build-stack-2.png
[12]: {{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/aws-stack-building.png
[13]: {{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/aws-stack-built.png
[14]: {{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/aws-vm-ready.png
[15]: {{ site.url }}/docs/terraform/providers/aws/r/instance.html/
