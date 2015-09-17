# fuseklient

Prototype that integrates [Fuse](https://github.com/bazil/fuse) and [Klient](https://github.com/koding/klient). Currently for OSX only. This is an in progress beta version. See https://github.com/koding/fuseklient/tree/alphabranch for alpha release.

## WARNING

  Use a new VM.

## Steps to get started:

    # ----- Following commands are run on your VM -----

    # Add your ssh key to `~/.ssh/authorized_keys` in a NEW Koding VM. This
    # will let us authenticate against Klient on that machine.
    # (Note: this step will be removed eventually.)

    # Get the IP of your VM from your VM. (Note: this step will be removed in eventually.)
    sent-hil: ~ $ curl ifconfig.co
    54.152.21.37

    # ----- Following commands are run on your local ----

    # Install osxfuse on your local via brew (requires working XCode).
    # (TODO: this step will be automated eventually.)
    brew install Caskroom/cask/osxfuse

    # Download latest release from https://github.com/koding/fuseklient/releases to your local.

    # Create a NEW folder in local to use as mount point:
    mkdir -p /path/to/local

    # Start daemon:
    ./fuseklient --ip=<ip> --remotepath=/home/<koding username>/Web --localpath=/path/to/local --sshuser=<koding username>

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
    * BETA
        move to new fuse library
        klient running on OSX
        klient auth
          ask kontrol for token
        kd mount (klient.mount method) - mount in goroutine in klient
          kd unmount
        kd install - dl os specific library
          use os specific init daemon to run binary
        invalidate local cache on file changes in user VM
        klient ps - return list of user VMs to mount
        deal with klient crashes
          unmount folders if it exists before starting
          handle mounting onto to previously mounted folder
    * 1.0
        kd run - run entire command on VM, return results
          shell hooks: fish, bash
        remaining FUSE operations
          lock resources in VM on open or write operations
        klient running on local with tunnel
        streaming support for kd run
        windows support

## Tests:

      go test ./..

## Debug:

    Pass `--debug=true` args to turn on application specific logs or `--fusedebug=true` to turn on library specific logs.

## Releases:

  Latest and previous releases are available at: https://github.com/koding/fuseklient/releases.

  For new releases:

      cd auth; go generate
      cd ../; go build
      tar -cvf fuseklient_OSX.tar fuseklient Readme.md

      # Upload to Github releases for distribution

## Notes:

  * Use fullpath in arguments, without ~.
  * Mounting on an existing folder won't overwrite contents, but they won't be visible while Fuse is running.
  * Use `tar -cvf fuseklient_OSX.tar fuseklient Readme.md` and upload to Github releases for distribution.
  * If you get `Device not configured` when trying to access mount when daemon is not running: do `diskutil unmount force <folder>`.
  * If you get `mount point <folder> is itself on a OSXFUSE volume`, do `diskutil unmount force <folder>`.
  * Not tested on Linux yet, will be supported by 1.0.
  * See https://github.com/jacobsa/fuse for more information.
