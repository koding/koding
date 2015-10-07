# fuseklient

Library that integrates [Fuse](https://github.com/bazil/fuse) and [Klient](https://github.com/koding/klient). This is an in progress beta version. See https://github.com/koding/fuseklient/tree/alphabranch for alpha release.

## Steps to get started:

    # ----- Download kd -----
    # kd is the cli to interact with klient and fuseklient
    curl https://koding-kd.s3.amazonaws.com/install-kd.sh -s | bash

    # Create a NEW folder in local to use as mount point:
    mkdir -p /path/to/local

    # Mount the remote machine:
    kd mount <machine name> </path/to/local> --remotepath=...

    # Mounted folder is now available. Open a terminal:
    ls -alh /path/to/local

## Following commands work on a mounted folder:

  * ls -alh folder/ file
  * cd folder/
  * mkdir -p folder/nested
  * mv folder/nested/ nested/
  * rm -rf folder/ file
  * touch file
  * echo 1 >> file
  * cat file
  * find ... # recursive search will be slow
  * grep ... # recursive search will be slow

## Milestones:

    * ALPHA - DONE Sept 3
        read operations
        klient authentication
        write operations
    * INTERNAL BETA - Done Sept 23
        move to new fuse library
        klient running on OSX
        klient auth
          ask kontrol for token
        kd mount (klient.mount method) - mount in goroutine in klient
          kd unmount
        kd install - dl os specific library
          use os specific init daemon to run binary
        klient ps - return list of user machines to mount
    * EXTERNAL BETA
        support flags in cli for optional args, ie --remotepath
        `kd update` after phone home to check for updates
        `kd ssh` that opens ssh connection on machine
        `kd remount`
          store state in ie bolt.db
          unmount folders if it exists before starting
          handle mounting onto to previously mounted folder
    * 1.0
        battle test
        invalidate local cache on file changes in user machine
        invalidate file list on file list changes
        kd run - run entire command on machine, return results
            shell hooks: fish, bash
        remaining FUSE operations
        lock resources in machine on open or write operations
        streaming support for kd run
        klient running on local with tunnel

## Tests:

      go test ./..

## Notes:

  * Mounting on an existing folder won't overwrite contents, but they won't be visible while Fuse is running.
  * If you get `Device not configured` when trying to access mount when daemon is not running: do `diskutil unmount force <folder>`.
  * If you get `mount point <folder> is itself on a OSXFUSE volume`, do `diskutil unmount force <folder>`.
  * See https://github.com/jacobsa/fuse for more information.
