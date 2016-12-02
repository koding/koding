---
layout: doc
title: Getting Started with DigitalOcean
permalink: /docs/getting-started-digitalocean
parent: /docs/home
---

# Getting Started with DigitalOcean

DigitalOcean is a very simple provider to get set up. This guide will take you through the whole process.

1. **[Sign Up](#sign-up)**
2. **[Create your Personal Access Token](#create-pat)**
3. **[Create your Stack](#create-stack)**
4. **[Set your Credentials](#set-creds)**
5. **[Save your Stack and Initialize](#save-init)**

***

## Sign Up <a name="sign-up"></a>

Using DigitalOcean as your provider will require you to sign up on their website. It will also require you to enter your credit card information and make an initial payment of at least $5. You can do that [here](https://cloud.digitalocean.com/registrations/new).

[Learn more about pricing](https://www.digitalocean.com/pricing/) at DigitalOcean.

***

## Create your Personal Access Token <a name="create-pat"></a>

Your DigitalOcean Personal Access Token will provide the credentials you need to instantiate your Stacks using DigitalOcean.

To generate your token:

1. [Login](https://cloud.digitalocean.com/login) to Digital Ocean
2. [Click API](https://cloud.digitalocean.com/settings/api/tokens) from the top menu
3. On the Tokens tab, click [Generate New Token](https://cloud.digitalocean.com/settings/api/tokens/new)
4. Name your new Token
5. Give it Read and Write permissions
6. Click Generate Token

> You'll use this token string as your credentials for creating VMs with Koding later in this guide.

***

## Create your Stack <a name="create-stack"></a>

***[What is a Stack?](/docs/what-is-a-stack)***

To create your Stack:

1. [Login to Koding](https://koding.com/Teams/Select)
2. Go to your [Dashboard](https://relepic.koding.com/Home) OR click [Stacks](https://relepic.koding.com/Home/Stacks) from your sidebar.
3. Either way, you'll default to the Stacks screen, so from that screen click [New Stack](https://relepic.koding.com/Stack-Editor/New)
4. Use the Wizard to create and  populate your Stack with some defaults, make sure you select Digital Ocean as provider

Your Stack will be created and will look something like this:

```
# Here is your stack preview
# You can make advanced changes like modifying your VM,
# installing packages, and running shell commands.

provider:
  digitalocean:
    access_token: '${var.digitalocean_access_token}'

resource:
  digitalocean_droplet:
    # this is the name of your VM
    example-instance:
      # and this is its identifier (required)
      name: example-instance
      # select your instance_type here: eg. 512mb
      size: 512mb
      # select your instance zone which must be in provided region: eg. nyc2
      region: nyc2
      # base image for your droplet
      image: ubuntu-14-04-x64
      # on user_data section we will write bash and configure our VM
      user_data: |-
        # let's create a file on your root folder:
        echo "hello world!" >> /helloworld.txt
        # please note: all commands under user_data will be run as root.
        # now add your credentials and save this stack.
        # once vm finishes building, you can see this file by typing
        # ls /
        #
        # for more information please click the link below "Stack Script Docs"
```
Make whatever changes you'd like to this script. Our [Stack Reference for DigitalOcean](/terraform/providers/do/) will help you see what is possible.

> You won't need to worry about the digitalocean_access_token variable. This will be automatically populated when you set up credentials in the next step.

***

## Set your Credentials <a name="set-creds"></a>

To add your DigitalOcean credentials:

1. From your Edit Stack screen (if you've just created the Stack, you will be on that screen by default) click on the Credentials tab
2. On the bottom right of the Credentials screen, click Create New
3. Name your Credentials whatever you like (pick something that will help you recognize them at a glance)
4. Copy the Personal Access token that you generated [earlier](#create-pat)
5. Click Save
6. You'll be taken back the Credentials tab where you'll see your new credentials listed by name. Click Use This & Continue to set them as the credentials for this stack.

***

## Save your Stack and Initialize <a name="save-init"></a>

Once you've created your Stack and set our credentials:

1. Click Save at the top right of the Edit Stack screen
2. Once the Stack successfully saves, you will see a new button next to Save: Initialize
3. Click Initialize

Your dev environment will begin to build based on your Stack and when it is finished, you can get to work!
