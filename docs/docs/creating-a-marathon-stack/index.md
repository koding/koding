---
layout: doc
title: Create a Marathon stack
permalink: /docs/creating-a-marathon-stack
parent: /docs/home
---

# {{ page.title }}

## Introduction

This guide will help you build a Marathon stack. [Marathon](https://mesosphere.github.io/marathon/) is a production-grade container orchestration platform for Mesosphere's [Datacenter Operating System (DC/OS)](https://mesosphere.com/product/) and [Apache Mesos](https://mesos.apache.org/).

You can configure the number of VMs and applications installed on each VM instance. Along with configuring VMs size. Your new team members will be able to use your stack to build their VMs environment and start working from day one.

## Step by step guide

1. Click **Stacks**

    ![Click Stacks][1]

2. Click **New Stack**

    ![Click new stack][2]

3. Choose **Marathon** and click **Create Stack**

    ![Choose Marathon provider][3]

4. You will now see the default stack template for Marathon. You can give your stack a name by clicking on the **Edit Name** on top beside your stack title. The _three tabs_ represent:

    1.  **Custom variables**: define custom variables to use in your stack template, hidden from Team _members_
    2.  **Readme**: this text will be shown in a message box when your team starts to build this stack. You can add instructions or notes for your team to read
    3.  **Credentials**: add your Marathon account credentials here

    ![Stack template][4]

    Review the **Stack Template** file to add/modify/remove any of your VM configurations

    >Click on the stack name to return to your **Stack template editor**.

5.  Edit your **Readme** section to greet your team and provide them with information or instructions. You can use [markdown](https://en.wikipedia.org/wiki/Markdown) format

    ![Read Me][5]

6.  Go to the **Credentials** tab and click **Add A New Credential**

    ![Credentials][6]

7.  For this step you will need to have your Marathon **URL**, **Basic Auth User** & **Basic Auth Password**. You can generate and acquire yours from your Marathon account

    - **Title**: add a name to your key pairs, _the title is a name for your reference it can be any name you want make it something easy to remember your credentials with._ 
    - **URL**: your Marathon URL
    - **Basic Auth User**: your Marathon basic authentication username
    - **Basic Auth Password**: your Marathon basic authentication password

    When you are done please click **Save This & Continue**.

    ![Credentials details][7]

8. Your Marathon credentials will be **verified** and you will be directed back to the Stack Template editor. Also the red exclamation mark that used to appear beside your **Credentials** tab should disappear. Click **SAVE** to save your stack and test your stack template file, it should save successfully

    ![Save Stack][8]

9. Click **Initialize** to initialize your stack

    > You can have multiple stacks within a team, click **Make Team Default** when you want to make this stack your team's default stack.

   ![Initialize Stack][9]

10. The build stack modal will appear, the *Instructions* tab will include the message you wrote in your **Read Me** tab. Click **Next** to continue

    ![Build Stack Instructions][10]

11. Click on **Build Stack** to start building your Stack

    > You can have multiple saved credentials to use within a team, the Credentials tab in your Build stack modal allows you to choose the one you want to use with this stack template.

    ![Build Stack Credentials][11]

    Your stack will start building..

    ![Stack Building][12]

12. Your stack was successfully built. Click **Start Coding** to start using your new VM.

    Congratulations, you can now start working on your new VM

    ![VM ready][13]

    You can also see the VM running on the backend

    ![Marathon Backend][14]

[1]: {{ site.url }}/assets/img/guides/azure/click-stacks.png
[2]: {{ site.url }}/assets/img/guides/azure/click-new-stack.png
[3]: {{ site.url }}/assets/img/guides/marathon/mar-provider.png
[4]: {{ site.url }}/assets/img/guides/marathon/mar-default-stack.png
[5]: {{ site.url }}/assets/img/guides/marathon/mar-readme.png
[6]: {{ site.url }}/assets/img/guides/marathon/mar-credentials.png
[7]: {{ site.url }}/assets/img/guides/marathon/mar-cred-complete.png
[8]: {{ site.url }}/assets/img/guides/marathon/mar-stack-save.png
[9]: {{ site.url }}/assets/img/guides/marathon/mar-stack-init.png
[10]: {{ site.url }}/assets/img/guides/marathon/mar-stack-build-1.png
[11]: {{ site.url }}/assets/img/guides/marathon/mar-stack-build-2.png
[12]: {{ site.url }}/assets/img/guides/marathon/mar-stack-building.png
[13]: {{ site.url }}/assets/img/guides/marathon/mar-vm-ready.png
[14]: {{ site.url }}/assets/img/guides/marathon/mar-backend.png
