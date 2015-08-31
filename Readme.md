# fuseproto

Prototype for getting [Fuse](https://github.com/bazil/fuse) to work with [Klient](https://github.com/koding/klient).

## WARNING

  Use a new VM.

## Steps to get started:

    # Install fuseproto to your local gobin
    go install git@github.com:koding/fuseproto.git

    # Get the ip of your VM, along with folder in that VM you want to mount locally
    # Or you can use mine:
    #   52.7.78.76 and /home/sent-hil/fusemount

    # Create a folder in local to mount external folder
    mkdir fusemount

    # Start daemon
    fuseproto --klientip=52.7.78.76 --externalpath=/home/sent-hil/fusemount --internalpath=./fusemount

    # In another terminal:
    cd fusemount
    ls -alh bitesized
