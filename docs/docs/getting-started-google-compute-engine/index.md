---
layout: doc
title: getting-started-google-compute-engine
permalink: /docs/getting-started-google-compute-engine
parent: /docs/home
---

# Getting Started with Google Compute Engine

Getting started with GCE is a fairly simple process:

1. **[Sign Up](#sign-up)**
2. **[Start a Project](#start-project)**
3. **[Create your Service Account Key](#create-key)**
4. **[Create your Stack](#create-stack)**
5. **[Set your Credentials](#set-creds)**
6. **[Save your Stack and Initialize](#save-init)**

***

## Sign Up <a name="sign-up"></a>

>Using GCE requires you to sign up for the Google Cloud Platform. This will also require you to provide personal information and a credit card. You'll be given a 60 day free trial and $300 in credit. Also, you won't be charged anything until you are once again prompted to do so. [Learn more about pricing](https://cloud.google.com/compute/pricing)

Sign up for Google Cloud Platform by going to [https://cloud.google.com/](https://cloud.google.com/). Once there, click 'Try It Free'. This will take you to a sign up wizard. Go through it (select your country, agree to terms, etc). At this point you'll be prompted for your personal information and a credit card. Once you offer all that, you'll be signed up and signed in!

> Once you are signed up, you will be prompted to Try Compute Engine, and will be offered a 15 minute quickstart. It might be a good idea to go through this process to get a solid understanding of the platform.

***

## Start a Project <a name="start-project"></a>

Google Cloud Platform starts you out in a default 'project' called My First Project. Projects are just a way of organizing your resources to be associated with the project they are used for. 

You might not want to stick with this default project, so go ahead and create a new one:

1. From the Dashboard or Home screen, you'll see a drop-down at the top of the screen with the name of your project displayed (defaulted to My First Project). Click that to open the menu.
2. Click Create Project.
3. This will open a dialog screen for you to name your project. Click Show Advanced Options to select your Region. This is important even if you don't change the region, because you'll be asked for the Region later when setting up credentials for your Stack.

> Take note not only of the Project Name but the Project ID. You will need this ID when creating credentials for your Koding Stack. 

***

## Create your Service Account Key <a name="create-key"></a>

Your Google Cloud Platform Service Account Key is a JSON file that you'll need to save to be used later as credentials for Koding to utilize GCE as your provider. 

To generate your key:

1. [Login](https://cloud.digitalocean.com/login) to Google Cloud Platform.
2. Go to the Credentials screen inside the API Manager. [Here is a direct link](https://console.cloud.google.com/apis/credentials)
3. On the Credentials tab (this is the default tab), click Create Credentials drop-down.
4. Choose Service Account Key from the list.
5. Set the Service Account to 'Compute Engine default service account'.
6. Set the Key Type to JSON.
7. Click Create.

This will save your Key as a file to your computer. 

> Make sure this is successful (that the file is saved successfully and that you can find the file). You'll need this later when you create your first Stack. 


***

## Create your Stack <a name="create-stack"></a>

***[What is a Stack?](/docs/what-is-a-stack)***

To create your Stack:

1. [Login to Koding](https://koding.com/Teams/Select)
2. Go to your [Dashboard](https://relepic.koding.com/Home) OR click [Stacks](https://relepic.koding.com/Home/Stacks) from your sidebar.
3. Either way, you'll default to the Stacks screen, so from that screen click [New Stack.](https://relepic.koding.com/Stack-Editor/New)
4. Use the Wizard to create and  populate your Stack with some defaults, make sure you select Google Compute Engine as provider.

Your Stack will be created and will look something like this:

```
# Here is your stack preview
# You can make advanced changes like modifying your VM,
# installing packages, and running shell commands.

provider:
  google:
    credentials: '${var.google_credentials}'
    project: '${var.google_project}'
    region: '${var.google_region}'

resource:
  google_compute_instance:
    # this is the name of your VM
    google-instance:
      # and this is its identifier (required)
      name: google-instance
      machine_type: f1-micro
      # base image for your instance
      disk:
        image: ubuntu-1404-lts
      # select your instance zone which must be in provided region: eg. us-central1-a
      zone: us-central1-a
      metadata:
        # on user_data sction will will write bash and configure our VM
        user-data: |-
          # let's create a file on your root folder:
          echo "hello world!" >> /helloworld.txt
          # please note: all commands under user_data will be run as root.
          # now add your credentials and save this stack.
          # once vm finishes building, you can see this file by typing
          # ls /
          #
          # for more information please click the link below "Stack Script Docs"
```

Make whatever changes you'd like to this script. Our [Stack Reference for Google](https://www.terraform.io/docs/providers/google/index.html) will help you see what is possible.

> You won't need to worry about the google_* variables. These will be automatically populated when you set up credentials in the next step. 

***

## Set your Credentials <a name="set-creds"></a>

To add your DigitalOcean credentials:

1. From your Edit Stack screen (if you've just created the Stack, you will be on that screen by default) click on the Credentials tab
2. On the bottom right of the Credentials screen, click Create New.
3. Name your Credentials whatever you like (pick something that will help you recognize them at a glance)
4. Enter your Project ID. If you don't know it, you should be able to find it [here](https://console.cloud.google.com/iam-admin/projects). 
5. Copy the contents of the Service Account Key file you saved to your computer [earlier.](#create-key)
6. Set the region of your project. 
7. Click Save.
8. You'll be taken back the Credentials tab where you'll see your new credentials listed by name. Click Use This & Continue to set them as the credentials for this stack. 

***

## Save your Stack and Initialize <a name="save-init"></a>

Once you've created your Stack and set our credentials:

1. Click Save at the top right of the Edit Stack screen
2. Once the Stack successfully saves, you will see a new button next to Save: Initialize
3. Click Initialize

Your dev environment will begin to build based on your Stack and when it is finished, you can get to work!


