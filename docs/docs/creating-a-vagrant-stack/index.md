---
layout: doc
title: Create a Vagrant stack
permalink: /docs/creating-a-vagrant-stack
parent: /docs/home
---

# {{ page.title }}

## Introduction

This guide will help you create a Vagrant stack. A Vagrant stack will use your local machine to host your VM. Vagrant works by using [virtual box][1] on your local or remote machine to create VMs. [Learn more about Vagrant here][2].

## Requirements:

To create a Vagrant Stack you need to have _Vagrant_ and _VirtualBox_ installed. **KD** will take care of installing them for you.

It is recommended that you choose the Vagrant stack if you have access to a physical machine. Vagrant will _not_ work on the below environments:

  - Cloud VMs like GCE or EC2
  - Windows (_not yet supported, work in progress_)

## Step by Step guide

1. **Install KD** by copying the KD CLI command and pasting in your _local terminal_. Click **Stacks -&gt; Koding Utilities** to find the KD CLI command

    > If you already have **KD** installed make sure you have the latest version by running **sudo kd update** in your local terminal.

    ![install-kd.png][3]

2. After the installation is successful on your **local terminal** , copy the **Kite Query ID**

    > If you already have the latest **KD** installed, you can run **kd version** on your local terminal to obtain your **Kite Query ID**.

    ![kite-query-id.png][4]

3. It's time to create your Vagrant stack, go to Koding again and click **STACKS**

    ![Create a new stack][5]

4. Click **New Stack**

    ![Click new stack][6]

5. Choose **Vagrant** as the provider and click **Create Stack**

    ![Vagrant provider][7]

6. You will now see the default stack template for Vagrant. You can give your stack a name by clicking on the **Edit Name** on top beside your stack title. The _three tabs_ represent:

    1.  **Custom variables**: define custom variables to use in your stack template, hidden from Team _members_
    2.  **Readme**: this text will be shown in a message box when your team starts to build this stack. You can add instructions or notes for your team to read
    3.  **Credentials**: add your Vagrant credentials here

    ![Stack template][8]
    Review the **Stack Template** file to add/modify/remove any of your VM configurations

    >You can add commands to run once your VM starts under the **user_data** section. For example you can choose to install services/packages once a VM starts. Commands under the **user_data** section will run as `root` when the VM boots.

    >Click on the stack name to return to your **Stack template editor**.

7.  Edit your **Readme** section to greet your team and provide them with information or instructions. You can use [markdown](https://en.wikipedia.org/wiki/Markdown) format

    ![Read Me][9]

8.  Go to the **Credentials** tab and click **Add A New Credentials**

    ![Credentials][10]

9. Give a **Title** to your Vagrant credentials, and paste the **Kite Query ID**&nbsp;you copied in step 2 into **Kite ID**. Then click **SAVE THIS &amp; CONTINUE**.

    ![Credentials details][11]

10. Your Vagrant credentials will be **verified** and you will be directed back to the Stack Template editor. Also the red exclamation mark that used to appear beside your **Credentials** tab should disappear. Click **SAVE** to save your stack and test your stack template file, it should save successfully

    ![Credentials Added][12]

11. Click **Initialize** to initialize your stack

    > You can have multiple stacks within a team, click **Make Team Default** when you want to make this stack your team's default stack.

    ![Initialize Stack][13]

12. The build stack modal will appear, the *Instructions* tab will include the message you wrote in your **Read Me** tab. Click **Next** to continue

    ![Build Stack Instructions][14]

13. Click on **Build Stack** to start building your Stack

    > You can have multiple saved credentials to use within a team, the Credentials tab in your Build stack modal allows you to chose the one you want to use with this stack template.

    ![Build Stack Credentials][15]

    Your stack will start building..

    ![Stack Building][16]

14. Your stack was successfully built. Click **Start Coding** to start using your new VM

    ![Stack built][17]

    Congratulations, your new VM terminal is ready

    ![VM ready][18]

## Advanced notes regarding Vagrant Stack template

This is an example stack script with more&nbsp;configuration options that you can use with your Vagrant Stack

``` yaml
    # Here is your stack preview
    # You can make advanced changes like modifying your VM,
    # installing packages, and running shell commands.

    resource:
      vagrant_instance:
        localvm:
          cpus: 2
          memory: 2048
          box: ubuntu/trusty64
          debug: true
          forwarded_ports:
          # mysql:
          - host:  13306
            guest: 3306
          # postgres:
          - host:  15432
            guest: 5432
          user_data: |-
            sudo apt-get install mysql-server postgresql -y
```

- **debug: true** makes all the Vagrant output to be logged in `/Library/Logs/klient.log`
- **forwarded_ports** forwards specified port from guest to host

[1]: http://www.virtualbox.org
[2]: https://www.vagrantup.com/about.html
[3]: {{ site.url }}/assets/img/guides/vagrant/install-kd.png
[4]: {{ site.url }}/assets/img/guides/vagrant/kite-query-id.png
[5]: {{ site.url }}/assets/img/guides/azure/click-stacks.png
[6]: {{ site.url }}/assets/img/guides/azure/click-new-stack.png
[7]: {{ site.url }}/assets/img/guides/vagrant/vagrant-provider.png
[8]: {{ site.url }}/assets/img/guides/vagrant/vagrant-create-stack.png
[9]: {{ site.url }}/assets/img/guides/vagrant/vagrant-readme.png
[10]: {{ site.url }}/assets/img/guides/vagrant/vagrant-credentials.png
[11]: {{ site.url }}/assets/img/guides/vagrant/vagrant-credentials-add-new.png
[12]: {{ site.url }}/assets/img/guides/vagrant/vagrant-credentials-added.png
[13]: {{ site.url }}/assets/img/guides/vagrant/vagrant-save-stack.png
[14]: {{ site.url }}/assets/img/guides/vagrant/vagrant-build-stack-1.png
[15]: {{ site.url }}/assets/img/guides/vagrant/vagrant-build-stack-2.png
[16]: {{ site.url }}/assets/img/guides/vagrant/vagrant-stack-building.png
[17]: {{ site.url }}/assets/img/guides/vagrant/vagrant-stack-built.png
[18]: {{ site.url }}/assets/img/guides/vagrant/vagrant-vm-ready.png
