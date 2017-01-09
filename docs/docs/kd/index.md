---
layout: doc
title: KD
permalink: /docs/kd
parent: /docs/home
---

# {{ page.title }}

KD is a tool to run commands & mount your remote VM files on your local machine. With KD you can:

1. Access your remote VM files and edit them using your favorite local IDE(s).
2. Run commands on your remote VM

## Table of Contents

  - [KD requirements](#requirements)
  - [Installing KD](#installation)
  - [KD commands](#kdcommands)
  - [KD help](#kdhelp)
  - [Using KD](#using-kd)
    - [kd list](#kd-list)
    - [kd mount](#kd-mount)
    - [kd run](#kd-run)
    - [kd update](#kd-update)
    - [kd version](#kd-version)
    - [kd uninstall](#kd-uninstall)

<a id="requirements"></a>

## KD requirements

Please note that the below is required for successful installation of **KD**:

1. sudo permission on your local machine is required
2. works only on **OSX** and **Linux**
3. **KD** is currently in beta

<a id="installation"></a>

## Installing KD

  Click on **STACKS** from the left side bar to open your **Dashboard**, and go to **Koding Utilities**

![kd-install-command.png][1]

  Copy the **kd** install command then paste it in your local machine terminal &amp; run..

```yaml
  john@johns-mac:~ $curl -sL https://kodi.ng/d/kd | bash -s 901f9a44
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

<a id="kdcommands"></a>

## KD full list of commands

You can get a list of KD commands using `kd help`

```
john@johns-mac:~ $ kd help

USAGE:
   kd command [command options]

COMMANDS:
   list, ls        List running machines for user.
   version         Display version information.
   mount, m        Mount a remote folder to a local folder.
   unmount, u      Unmount previously mounted machine.
   remount, r      Remount previously mounted machine using same settings.
   ssh, s          SSH into the machine.
   run             Run command on remote or local machine.
   repair          Repair the given mount
   status          Check status of the KD Daemon.
   update          Update KD Daemon to latest version.
   restart         Restart the KD Daemon.
   start           Start the KD Daemon.
   stop            Stop the KD Daemon.
   uninstall       Uninstall the KD Daemon.
   install         Install the KD Daemon.
   metrics         Internal use only.
   autocompletion  Enable autocompletion support for bash and fish shells
   cp              Copy a file from one one machine to another
   log             Display logs.
   open            Open the given file(s) on the Koding UI
   help, h         Shows a list of commands or help for one command
```
<a id="kdhelp"></a>

## KD help

To know how to use a particular KD command, you can get help simply by running `kd help <command>`

For example, to learn more on using the command `kd mount` we would run `kd help mount`

```
john@johns-mac:~ $ kd help mount
USAGE:
    kd mount [optional args] <alias:remote path> <local folder>
DESCRIPTION
    Mount folder from remote machine to local folder.
    Alias is the local identifer for machine in 'kd list'.

    Local folder can be relative or absolute path, if
    folder doesn't exit, it'll be created.

    By default this uses FUSE to mount remote folders.
    For best I/O performance, especially with commands
    that does a lot of filesystem operations like git,
    use --oneway-sync.
```
<a id="using-kd"></a>

## Using KD

Here's a list of the common KD commands

<a id="kd-list"></a>

### kd list

Run `kd list` to view all your Koding cloud VMs:

```
  john@johns-mac:~ $ kd list
      TEAM   LABEL           IP        ALIAS   MOUNTED     PATHS
  1. bloom   example_1  52.49.116.216  grape
```

<a id="kd-mount"></a>

### kd mount < vm alias > < local mount folder >

Run `kd mount` to mount your cloud VM(s) to a local folder and start editing your files using your favorite local editors. You can use the **ALIAS** name to mount your VM:

```
  john@johns-mac:~ $ kd mount grape ./grape
  The mount folder does not exist, would you like to create it? [Y/n]y
  Mount success.
  john@johns-mac:~ $ cd grape
  john@johns-mac:~/grape $ ls
  john@johns-mac:~/grape $ ls -a
  .bash_logout .bashrc .config .profile
```

You have now mounted the cloud VM on a local folder called '_grape_'. You can mount your VM on any folder name. All changes within your mounted folder are actually happening on your cloud VM.

> Use the `-p` option with `kd mount` if you have a slow connection. It will force **kd** to retrieve only top level folder/files. Rest is fetched on request (fastest to mount). For more options run `kd help mount`

<a id="kd-run"></a>

### kd run < command >

`kd run` is very useful as you can use it to run commands on your remote VM.

<a id="kd-update"></a>

### kd update

`kd update` will update **kd** to the newest version

```
john@johns-mac:~ $ sudo kd update
Password:
Updating...
Stopping KD Daemon...
Successfully updated to latest version of kd.
```

<a id="kd-version"></a>

### kd version

`kd version` will show the installed **kd** version

```
john@johns-mac:~ $ kd version
Installed Version: 0.1.74
Latest Version: 0.1.74
Environment: production
Kite Query ID: a7e1e03f-7f01-47a3-b4ac-2566b5256564
```

<a id="kd-uninstall"></a>

### kd uninstall

`sudo kd uninstall` will uninstall **kd** from your local machine.


[1]: {{ site.url }}/assets/img/guides/kd/kd-install-command.png
