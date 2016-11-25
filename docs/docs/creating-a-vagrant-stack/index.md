---
layout: doc
title: Create a Vagrant stack
permalink: /docs/creating-a-vagrant-stack
parent: /docs/home
---

# {{ page.title }}

# Vagrant Stack

This guide will help you create a Vagrant stack. A Vagrant stack will use your local machine to host your VM. Vagrant works by using [virtual box][1] on your local or remote machine to create VMs. [Learn more about Vagrant here][2].

## Requirements:

To create a Vagrant Stack you need to have _Vagrant_ and _VirtualBox_ installed. **KD** will take care of installing them for you.

It is recommended that you choose the Vagrant stack if you have access to a physical machine. Vagrant will _not_ work on the below environments:

  - Cloud VMs like GCE or EC2
  - Windows (_not yet supported, work in progress_)

## Step by Step guide

1. **Install KD** by copying the KD CLI command and pasting in your _local terminal_. Click **Stacks -&gt; Koding Utilities** to find the KD CLI command.

    > If you already have **KD** installed make sure you have the latest version by running **sudo kd update** in your local terminal.

    ![install-kd.png][3]

2. After the installation is successful on your **local terminal** , copy the **Kite Query ID**.

    > If you already have the latest **KD** installed, you can run **kd version** on your local terminal to obtain your **Kite Query ID**.

    ![kite-query-id.png][4]

3. It's time to create your Vagrant stack, go to Koding again and click **STACKS**.

    ![step001.png][5]

4. Click **New Stack** button.

    ![step002.png][6]

5. Choose **Vagrant** as the provider.

    ![provider-vagrant.png][8]

6. Rename your Stack to something you remember, we named ours **Vagrant Stack**.

    ![rename-stack.png][9]

7. Move to the **Credentials** tab and give any **Title** to your credential, and paste the **Kite Query ID**&nbsp;you copied in step 2 into **Kite ID**. Then click **SAVE THIS &amp; CONTINUE**.

    ![credentials.png][10]

8. Click **Save**, then **Initialize** and follow the stack building wizard to build your Vagrant Stack. Once you are done, you will be able to use your Vagrant VM on Koding.

    ![vagrant-stack-started.png][11]

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
[5]: {{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/step001.png
[6]: {{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/step002.png
[7]: {{ site.url }}/assets/img/guides/stack-aws/0-create-aws-stack/step003.png
[8]: {{ site.url }}/assets/img/guides/vagrant/provider-vagrant.png
[9]: {{ site.url }}/assets/img/guides/vagrant/rename-stack.png
[10]: {{ site.url }}/assets/img/guides/vagrant/credentials.png
[11]: {{ site.url }}/assets/img/guides/vagrant/vagrant-stack-started.png
