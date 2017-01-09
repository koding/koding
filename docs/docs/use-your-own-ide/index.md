---
layout: doc
title: Use your own IDE
permalink: /docs/use-your-own-ide
redirect_from: "/docs/connect-your-machine"
parent: /docs/home
---

# {{ page.title }}

### INTRODUCTION:

You can use your own machine to connect to your VMs and edit your files using your favorite local tools by using **kd** tool.

Please note that to install **kd**:

1. sudo permission on your local machine is required
2. works only on OSX and Linux
3. **kd** is currently in beta

## Step 1: Get the _**kd**_ install command

Click on **STACKS** from the left side bar to open your **Dashboard**, and go to **Koding Utilities**

![kd-install-command.png][1]

## Step 2: Copy the command and paste it into your local machine

Click **Select** and copy the **kd** install command

_paste in terminal &amp; run.._

```bash
    john@johns-mac:~ $ curl -sL https://kodi.ng/d/kd | bash -s 901f9a44
    Hello, this is the Koding application (kd) installer.
    This installer requires sudo permissions, please input password if prompted...
    Password:

    Downloading kd...
     % Total % Received % Xferd Average Speed Time Time Time Current
     Dload Upload Total Spent Left Speed
    100 11.0M 100 11.0M 0 0 160k 0 0:01:10 0:01:10 --:--:-- 242k
    Created /usr/local/bin/kd

    Downloading...
    Created /opt/kite/klient/klient
    Authenticating you to the KD Daemon

    Authenticated successfully
    Created /etc/kite/kite.key
    Verifying installation...

    Successfully installed and started the KD Daemon!
    Success! kd has been successfully installed. Please run the
    following command for more information:

     kd -h

    john@johns-mac:~ $
```

## Step 3: Mount your VM to local folder

Use the `kd list` and `kd mount` to mount your machine to a local folder

Use `kd list` to view all your Koding cloud VMs:

```bash
  john@johns-mac:~ $ kd list
      TEAM   LABEL           IP        ALIAS   MOUNTED     PATHS
  1. bloom   example_1  52.49.116.216  grape
```

Use `kd mount` to mount your cloud VM to a local folder and start editing your files using your favorite local editors. You can use the **ALIAS** name to mount your VM:

```bash
  john@johns-mac:~ $ kd mount grape ./grape
  The mount folder does not exist, would you like to create it? [Y/n]y
  Mount success.
  john@johns-mac:~ $ cd grape
  john@johns-mac:~/grape $ ls
  john@johns-mac:~/grape $ ls -a
  .bash_logout .bashrc .config .profile
```

You have now mounted the cloud VM on a local folder called '_grape_'. You can use to mount you VM on any folder name. All changes within your mounted folder will actually occur on your cloud VM. Here's a quick walkthrough of how you can use **kd** to edit your cloud VM files

![kd.gif][2]

Congratulations, you are done! You now know how to use **kd** to mount your VM on a local folder and start using your favorite editor. All your edits will be saved on your cloud machine(s).

See more information about [KD here][3]

[1]: {{ site.url }}/assets/img/guides/kd/kd-install-command.png
[2]: {{ site.url }}/assets/img/guides/kd/kd.gif
[3]: {{ site.url }}/docs/kd
