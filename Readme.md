# fuseklient

Prototype that integrates [Fuse](https://github.com/bazil/fuse) and [Klient](https://github.com/koding/klient). Currently for OSX only.

## WARNING

  Use a new VM.

## Steps to get started:

    # Add your ssh key to `~/.ssh/authorized_keys` in a NEW Koding VM. This
    # will let us authenticate against Klient on that machine.
    # (Note: this step will be removed in 1.0).

    # Download latest fuseklient from https://github.com/koding/fuseklient/releases.

    # Get the IP of your VM and folder in that VM you want to mount locally.

    # Create a NEW folder in local to use as mount point:
    mkdir -p <fullpath>/local

    # Start daemon:
    ./fuseklient --klientip=<ip> --externalpath=/path/to/external --internalpath=/path/to/local --user=<koding username> --debug=true

    # Mounted folder is now available:
    ls -alh /path/to/local

## Following commands work on a mounted folder.

  * ls -alh folder/ file
  * cd folder/
  * mkdir -p folder/nested
  * mv folder/nested/ nested/
  * rm -rf folder/ file
  * cat file
  * touch file
  * echo 1 >> file
  * find ... # recursive search will be slow
  * grep ... # recursive search will be slow

## Milestones:

    * ALPHA
        read operations
        klient authentication
        write operations
    * BETA
        klient running on OSX
        integrate fuseklient into klient
          `klient mount --vm`
        invalidate local cache on file changes in user VM
        kd ... - run entire command on VM, return results
        shell hooks: fish, bash
    * 1.0
        klient ps - return list of user VMs to mount
        lock resources in VM on open or write operations
        remaining FUSE operations

## Notes:

  * Use fullpath in arguments.
  * Mounting on an existing folder won't overwrite contents, but they won't be visible while Fuse is running.
  * Do `go generate` if you make changes to `install-alpha.sh`
  * Use `tar -cvf fuseklient_OSX.tar fuseklient Readme.md` for distribution.
  * If you get `Device not configured` when trying to access mount when daemon is not running: do `diskutil unmount force <folder>`.
  * If you get `mount point <folder> is itself on a OSXFUSE volume`, do `diskutil unmount force <folder>`.
