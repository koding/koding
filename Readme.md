# fuseproto

Prototype that integrates [Fuse](https://github.com/bazil/fuse) and [Klient](https://github.com/koding/klient).

## WARNING

  Use a new VM.

## Steps to get started:

    # Install fuseproto to your local gobin:
    go install git@github.com:koding/fuseproto.git

    # Get the ip of your VM, along with folder in that VM you want to mount locally
    # Or you can use mine:
    #   52.7.78.76 and /home/sent-hil/fusemount

    # Create a folder in local to mount external folder:
    mkdir -p <fullpath>/local

    # Start daemon:
    fuseproto --klientip=52.7.78.76 --externalpath=/home/sent-hil/fusemount --internalpath=<fullpath>/local --debug=true

    # In another terminal:
    cd local
    ls -alh bitesized

    # If you get `Device not configured` when trying to access mount when daemon is not running:
    diskutil unmount force <folder>

    # If you get `mount point <folder> is itself on a OSXFUSE volume`:
    diskutil unmount force <folder>

## Milestones:

    * 0.1 - DONE Aug 31
        read operations
        move code from old prototype to new fuseproto
    * 0.2
        klient authentication
    * 0.3 - DONE Sept 2
        write operations
    * 0.4
        integration into klient
            merge fuseproto into klient
        klient method to send events to invalidate cache on file changes
        lock resources in VM on open or write operations
    * 0.5
        klient ps - return list of user VMs to mount
    * 0.6
        kd ... - run entire command on VM, return results
            similar to watch
            mainly for find, grep etc. recursive operations
    * 0.7
        remaining FUSE operations

## Notes:

  * Use fullpath in arguments.
  * Mounting on an existing folder won't overwrite contents, but they won't be visible while fuseproto is running.
