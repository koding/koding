---
layout: doc
title: Create a SoftLayer stack
permalink: /docs/creating-a-softlayer-stack
parent: /docs/home
---

# {{ page.title }}

## Introduction

This guide will help you build a SoftLayer stack. [SoftLayer](http://www.softlayer.com/) by IBM offers bare metal servers and virtual servers integrated in a seamless, fully-automated platform on IBM data centers.

You can configure the number of VMs and applications installed on each VM instance. Along with configuring VM size and region. Your new team members will be able to use your stack to build their VMs environment and start working from day one.

## Step by step guide

1. Click **Stacks**

    ![Click Stacks][1]

1. Click **New Stack**

    ![Click new stack][2]

2. Choose **SoftLayer** and click **Create Stack**

    ![Choose SoftLayer provider][3]

3. You will now see the default stack template for SoftLayer. You can give your stack a name by clicking on the **Edit Name** on top beside your stack title. The _three tabs_ represent:

    1.  **Custom variables**: define custom variables to use in your stack template, hidden from Team _members_
    2.  **Readme**: this text will be shown in a message box when your team starts to build this stack. You can add instructions or notes for your team to read
    3.  **Credentials**: add your SoftLayer account credentials here

    ![Stack template][4]

    Review the **Stack Template** file to add/modify/remove any of your VM configurations

    >You can add commands to run once your VM starts under the **user_data** section. For example you can choose to install services/packages once a VM starts. Commands under the **user_data** section will run as `root` when the VM boots.

    >Click on the stack name to return to your **Stack template editor**.

4.  Edit your **Readme** section to greet your team and provide them with information or instructions. You can use [markdown](https://en.wikipedia.org/wiki/Markdown) format

    ![Read Me][5]

5.  Go to the **Credentials** tab and click **Add A New Credentials**

    ![Credentials][6]

6.  For this step you will need to have your SoftLayer **VPN username** & **API Key** from your SoftLayer account.

    - **Title**: add a name to your key pairs, _the title is a name for your reference it can be any name you want make it something easy to remember your credentials with._ 
    - **VPN username**: your SoftLayer username including prefix (_ex: SL or IBM_)
    - **API Key**: your SoftLayer API KEY

    When you are done please click **Save This & Continue**.

    ![Credentials details][7]

7. Your SoftLayer credentials will be **verified** and you will be directed back to the Stack Template editor. Also the red exclamation mark that used to appear beside your **Credentials** tab should disappear. Click **SAVE** to save your stack and test your stack template file, it should save successfully

    ![Save Stack][8]

8. Click **Initialize** to initialize your stack

    > You can have multiple stacks within a team, click **Make Team Default** when you want to make this stack your team's default stack.

   ![Initialize Stack][9]

9. Now let's start building our stack

    > You will notice that the first page in the building stack window contains the message we wrote in our Read Me tab in our stack. This is the same message your team will see when they build their stack. It is a good practice to include information about your project or stack for your teammates.

    Click **Next**

   ![Build Stack Instructions][10]

10. Make sure the correct credentials are selected (you can save multiple credentials) and click **Build Stack**

    > You can have multiple saved credentials to use within a team, the Credentials tab in your Build stack modal allows you to choose the one you want to use with this stack template.

    ![Build Stack Credentials][11]

    Your stack will start building..

    ![Stack building][12]

11. Your stack was successfully built. Click **Start Coding** to start using your new VM

    ![Stack built][13]

    Congratulations, your new VM terminal is ready

    ![VM ready][14]

> See more options and information for creating a SoftLayer instance here [SOFTLAYER_INSTANCE][15].

[1]: {{ site.url }}/assets/img/guides/azure/click-stacks.png
[2]: {{ site.url }}/assets/img/guides/azure/click-new-stack.png
[3]: {{ site.url }}/assets/img/guides/softlayer/sl-provider.png
[4]: {{ site.url }}/assets/img/guides/softlayer/sl-default-stack.png
[5]: {{ site.url }}/assets/img/guides/softlayer/sl-readme.png
[6]: {{ site.url }}/assets/img/guides/softlayer/sl-new-credentials.png
[7]: {{ site.url }}/assets/img/guides/softlayer/sl-credentials-complete.png
[8]: {{ site.url }}/assets/img/guides/softlayer/sl-save-stack.png
[9]: {{ site.url }}/assets/img/guides/softlayer/sl-stack-initialize.png
[10]: {{ site.url }}/assets/img/guides/softlayer/sl-stack-build-1.png
[11]: {{ site.url }}/assets/img/guides/softlayer/sl-stack-build-2.png
[12]: {{ site.url }}/assets/img/guides/softlayer/sl-stack-building.png

[13]: {{ site.url }}/assets/img/guides/softlayer/sl-stack-built.png
[14]: {{ site.url }}/assets/img/guides/softlayer/sl-vm-ready.png
[15]: {{ site.url }}/docs/terraform/providers/softlayer/index.html/
