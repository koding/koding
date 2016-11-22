---
layout: doc
title: getting-started-aws
permalink: /docs/getting-started-aws
parent: /docs/home
---

# Getting Started with AWS

AWS is a full-featured Cloud provider that is also fairly easy to integrate with Koding:

1. **[Sign Up](#sign-up)**
2. **[Subscribe to EC2](#subscribe)**
3. **[Get your Access Key ID & Secret Access Key](#get-key)**
4. **[Create your Stack](#create-stack)**
5. **[Set your Credentials](#set-creds)**
6. **[Save your Stack and Initialize](#save-init)**

***

## Sign Up <a name="sign-up"></a>

Like with all cloud providers, AWS requires you to sign up:

1. Go to https://aws.amazon.com/free/.
2. Click Sign In to the Console. This will start the process of signing up after you select "I am a new user."
3. Go through adding your Contact Info, Payment Info, verifying your identity, choosing a support plan. 
4. Confirm your information and you should be good to go!

[Learn more about pricing](https://aws.amazon.com/ec2/pricing/) for AWS.

***

## Subscribe to EC2 <a name="subscribe"></a>

Now that you've signed up for AWS, you must subscribe to the Elastic Compute Cloud (EC2):

1. Log into the AWS Console [here.](https://console.aws.amazon.com/console/home)
2. Open the Services menu from the top navbar. 
3. In that menu, select EC2 from the Compute category.
4. You'll be taken to a screen prompting you to subscribe.  

> This requires verification and can take some time.

***

## Get your Access Key ID & Secret Access Key <a name="get-key"></a>

In order for Koding to integrate with EC2, we'll need your Access Key ID and Secret Access Key. 

> AWS provides a guide for getting your Access Key and ID: http://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html

We've copied that guide here:

1. Use your AWS account email address and password to sign in to the AWS Management Console.
> If you previously signed in to the console with IAM user credentials, your browser might open your IAM user sign-in page. You can't use the user sign-in page to sign in with your root credentials. Instead, choose Sign in using AWS Account credentials near the bottom of the page to go to the account sign-in page. In the upper right of the console, choose the account name or number and then choose Security Credentials.

2.  On the AWS Security Credentials page, expand the Access Keys (Access Key ID and Secret Access Key) section.
3. Choose Create New Access Key. You can have a maximum of two access keys (active or inactive) at a time.
4. Choose Download Key File to save the access key ID and secret access key to a .csv file on your computer. After you close the dialog box, you can't retrieve this secret access key again.
5. To disable an access key, choose Make Inactive. AWS denies requests signed with inactive access keys. To re-enable the key, choose Make Active.
6. To delete an access key, choose Delete. To confirm that the access key was deleted, look for Deleted in the Status column.

> Before you delete an access key, make sure it is no longer in use. You can't recover a deleted access key.

***

## Create your Stack <a name="create-stack"></a>

***[What is a Stack?](/docs/what-is-a-stack)***

To create your Stack:

1. [Login to Koding](https://koding.com/Teams/Select)
2. Go to your [Dashboard](https://relepic.koding.com/Home) OR click [Stacks](https://relepic.koding.com/Home/Stacks) from your sidebar.
3. Either way, you'll default to the Stacks screen, so from that screen click [New Stack](https://relepic.koding.com/Stack-Editor/New)
4. Use the Wizard to create and  populate your Stack with some defaults, make sure you select Amazon Web Services as provider

Your Stack will be created and will look something like this:

```
# Here is your stack preview
# You can make advanced changes like modifying your VM,
# installing packages, and running shell commands.

provider:
  aws:
    access_key: '${var.aws_access_key}'
    secret_key: '${var.aws_secret_key}'
resource:
  aws_instance:
    example_1:
      instance_type: t2.nano
      ami: ''
      tags:
        Name: '${var.koding_user_username}-${var.koding_group_slug}'
      user_data: |-
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        apt-get -y install ruby nginx
    example_2:
      instance_type: t2.nano
      ami: ''
      tags:
        Name: '${var.koding_user_username}-${var.koding_group_slug}'
      user_data: |-
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        apt-get -y install mysql-server
```
Make whatever changes you'd like to this script. Our [Stack Reference for AWS](https://www.terraform.io/docs/providers/aws/index.html) will help you see what is possible.

> You won't need to worry about the aws_*_key variables. These will be automatically populated when you set up credentials in the next step. 

***

## Set your Credentials <a name="set-creds"></a>

To add your AWS credentials:

1. From your Edit Stack screen (if you've just created the Stack, you will be on that screen by default) click on the Credentials tab
2. On the bottom right of the Credentials screen, click Create New
3. Name your Credentials whatever you like (pick something that will help you recognize them at a glance)
4. Paste in the ID and Key that you obtained [earlier](#create-key)
5. Click Save
6. You'll be taken back the Credentials tab where you'll see your new credentials listed by name. Click Use This & Continue to set them as the credentials for this stack. 

***

## Save your Stack and Initialize <a name="save-init"></a>

Once you've created your Stack and set our credentials:

1. Click Save at the top right of the Edit Stack screen
2. Once the Stack successfully saves, you will see a new button next to Save: Initialize
3. Click Initialize

Your dev environment will begin to build based on your Stack and when it is finished, you can get to work!


