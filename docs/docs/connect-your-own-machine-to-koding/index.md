---
layout: doc
title: Connect your own machine
permalink: /docs/connect-your-own-machine-to-koding
redirect_from: "/docs/connect-your-machine"
parent: /docs/home
---

# {{ page.title }}

### What does "connect your own machine" mean?

This feature allows you to connect your own machine, physical or virtual (_DigitalOcean, GCE, others..._), to your Koding for Teams account so that it will show up in the sidebar just like a regular Koding VM. This means that once your machine is connected to Koding for Teams, you can open a Terminal and any file on that machine directly from your Koding for Teams account! You can even start collaboration sessions!

### What types of machines can I connect to my Koding for Teams account?

Presently, the following are the requirements for any machine that can be connected to Koding:
- the machine needs to have a public IP address
- the machine must be running Ubuntu Linux 13.x or 14.x (support for 15.x is coming)
- you must have root/sudo access on the system

In addition to these machine related requirements, you must also ensure that you have the following ports open (in case you are running a firewall):

- 80/tcp
- 56789/tcp

### How does Koding make this happen?

The steps are outlined below but in a nutshell, what happens is that you download our "Koding Service Connector" to your machine and this service acts like a "bridge" between your machine and your Koding account.

### How can I connect my own machine to Koding?

Connecting your machine to Koding is easy, just follow these steps but first make sure that the requirements stated above are met:

1. Click on **STACKS**

    ![step1stacks.png][2]

2. Go to **Virtual Machines**, and click **Add Your Own Machine**

    ![access-add-machine2.png][3]

3. In the dialogue box that appears, **copy** the install script and run it on your machine and leave this modal open (_check below tip_)

    ![add-your-own-machine-modal.png][4]

    > Leave the dialogue box open while you run the install script on your machine. **This is a** **requirement** since we are **_listening_**&nbsp;for a connection from your machine. Also, make sure you have root access to run the install script otherwise it will fail.

4. The install script will download the necessary software, configure it and install it on your machine

    ![kd-success.png][5]

5. Once the install script is done running on your machine, within a few seconds your machine should show up in the sidebar

    ![congrats.png][6]

### Are there any limits to how many machines I can connect?

Our free accounts are restricted to one external machine and paid accounts don't have any limits to the number of machines/VMs they can connect to their Koding account.

### How can I disconnect a machine that I have connected to my Koding account?

To disconnect a machine, simply go to **Stacks -&gt; Virtual Machines**&nbsp;tab&nbsp;-**&gt; Connected Machines**&nbsp;section and click on **VM Disconnect**.&nbsp;

> Notice: Disconnecting will just break the connection between Koding and your machine. Your machine will still be running and all files will be available on it.

If you wish to completely uninstall the Koding Connector Service from your machine, simply run this command on the machine that you had connected:

    sudo dpkg -P klient


[2]: {{ site.url }}/assets/img/guides/add-digitalocean/step1stacks.png
[3]: {{ site.url }}/assets/img/guides/add-digitalocean/access-add-machine2.png
[4]: {{ site.url }}/assets/img/guides/add-digitalocean/add-your-own-machine-modal.png
[5]: {{ site.url }}/assets/img/guides/add-digitalocean/kd-success.png
[6]: {{ site.url }}/assets/img/guides/add-digitalocean/congrats.png
