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

1. Click **STACKS**

![step001.png]({{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/step001.png)

2. Click **New Stack** button

![step002.png]({{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/step002.png)

4. Click **amazon web services** and click **Next**

![step004.png]({{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/step004.png)

7.  You can give your stack a name by clicking on the **Stack Name**. In this modal you will find _four tabs_:

    1.  **Stack template**: configuration file for your VMs
    2.  **Custom variables** to define custom variables to be used in your stack template
    3.  **Readme** This text will be shown in a message box when your team uses this stack
    4.  **Credentials** add your AWS credentials here
8.  Review the **Stack Template** (see point 6.1) file to add/modify/remove any of your VM configurations
![step008.png]({{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/step008.png)
    **Note:** You will notice that the _Stack File_ will include the required commands to install your selected services/packages under the `user_data` section. You may further include any commands you want to run when the machine starts in the stack file under the same section.
9.  Edit your **Readme** (see point 6.3) file to greet your team and provide them with information about this particular stack ![step009.png]({{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/step009.png "step_readme.png")
10.  Go to the **Credentials** tab and click **Create New**
![step010.png]({{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/step010.png "step7.png")
11.  For this step you will need to have your Amazon AWS **Access Key ID** & **Secret Access Key**. You can generate and acquire yours from your AWS account.

> **Tip**
> If you do not have an AWS account yet, please create one on Amazon AWS here [aws.amazon.com](http://aws.amazon.com), login and make sure you subscribe to EC2 service on AWS console, click **Services** (top left) **-> EC2**. 
> Then <span>_follow first 5 steps_ at the bottom of this [AWS guide ](http://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html)to generate your keys.

## Add an AWS Credential

> **Alert**
> If you followed AWS recommended tip on creating an IAM user rather than using your AWS root user account to generate the crednetials, you need to make sure your new IAM user has enough privileges to create EC2's. Please follow our [Setup AWS IAM user](/docs/setup-aws-iam-user) guide to know which roles should be assigned for this user in order to use the credentials to build your stack successfully.

- Add a **Title** to your key pairs - _the title is a name for your reference it can be any name you want._ 
- Add your AWS keys - **Access Key ID** & **Secret Access Key**.
- Choose a **Region** - (data center location) where you want your VMs to be created.
When you are done please click **Save**.
![step011.png]({{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/step011.png)

12. Click **USE THIS & CONTINUE** to use your AWS keys, you should see your key highlighted with "**IN USE**" if all went well. You can also **show** and **delete** your AWS keys when you hover your mouse over your AWS key.  ![step012_2.png]({{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/step012_2.png "step8.png")
13. You will be directed to the Stack Template section. Click **SAVE** to save your stack and test your stack configuration file ![step013.png]({{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/step013.png "step9_success.png")
14. Click on **Build Stack** and your new Stack will start building.. ![step014.png]({{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/step014.png "step12_buildstackready.png")
  Stack building.. ![step014_2.png]({{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/step014_2.png)
15. Congratulations, your Stack was successfully built and you can now use your new VM ![step015.png]({{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/step015.png)

## Advanced notes for creating an AWS Stack

This is an example stack script the defines the drive size which you can use with your AWS Stack:

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
