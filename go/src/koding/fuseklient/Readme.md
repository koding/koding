# fuseklient

Library that integrates [Fuse](https://github.com/bazil/fuse) and [Klient](https://github.com/koding/klient). This is an in progress beta version. See https://github.com/koding/fuseklient/tree/alphabranch for alpha release.

## Steps to get started:

    # ----- Download kd from <your team>.koding.com -----
    # kd is the cli to interact with klient and fuseklient
    curl -L kodi.ng/c/p/kd | bash -s <token>

    # Mount the remote machine on `folder1`
    kd mount <machine name> ./folder

    # Mounted folder is now available. Open a terminal:
    ls -alh ./folder

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

## Tests:

      go test ./..

## Notes:

  * If you get `Device not configured` when trying to access mount when daemon
    is not running: do `diskutil unmount force <folder>`.
  * If you get `mount point <folder> is itself on a OSXFUSE volume`, do `diskutil unmount force <folder>`.
  * See https://github.com/jacobsa/fuse for more information.

## Naming guide

  * Dir over Directory or Folder.
  * Use crud names in transports, ie CreateDir instead of MkDir.
  * Mode over Permissions.
