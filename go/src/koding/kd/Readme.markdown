# kd

kd allows you to use your local IDE and tools to interact with a Koding VMs.
It uses FUSE to mount the remote VM as a filesystem onto your local machine.

In addition it allows you to run commands/ssh on your remote machine from local
terminal.

## Parts

  * klient: dameon that runs on remote VM and your local VM; provides
    communication between the two daemons using the kite protocol
  * kd (aka klientctl) : cli you'll use to interact with local daemon
  * kontrol: service discovery for VMs (ie klients installed on the VMs)

## Commands

See kd -h for help.

    # Get list of remove VMs available to mount:
    kd list

    # Mount remote VM onto to your local VM:
    kd mount <name> <additional-args>

## Installation

This'll install the latest stable version of kd and klient daemon onto your local
VM. It'll authenticate to koding.com and you'll be able to see VMs
registered to koding.com

    # ----- Download kd from <your team>.koding.com -----
    # kd is the cli to interact with klient and fuseklient
    curl -L kodi.ng/d/kd | bash -s <token>

    # Mount the remote VM on `folder`
    kd mount <name> ./folder

If you wish to develop kd you'll need the following depedencies.

## Dependencies:

  * Go: Version 1.5 or later required. Please set $GOPATH to ?
  * Fuse:
    * OSX: Download & install FUSE 2.8 from "http://downloads.sourceforge.net/project/osxfuse/osxfuse-2.8.0/osxfuse-2.8.0.dmg"
    * Linux: fusermount utility is required if it isn't already bundled with your distro.

## Getting started

    # only do this if you've installed kd before
    sudo kd uninstall

### Klient

    # Builds, installs and restarts Klient daemon:
    make klient

### Kd

    # Builds & installs kd
    make kd

### Kontrol

Currently we're using koding.com kontrol to develop against. We'll soon provide
a way to run Kontrol locally.
