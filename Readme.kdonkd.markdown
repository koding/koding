# Connect Koding on Koding

Staying true to our tagline of “Say goodbye to localhost”, we’ve moved development of koding.com from our local machines to team on koding.com. It’s a big undertaking, but it’s necessary to do it to understand the day to day experience of using teams on koding.com. Support for local development (boot2docker) is now deprecated and will be removed very soon.

You should have been invited to https://team.koding.com already. Please do the following:

* [Build your stack](http://take.ms/GxI9N) on https://team.koding.com and follow instructions there to get a working version of koding on your VM.
* [Add your team](https://monosnap.com/file/vq1fJe8508BZp5zTb7CBNeK2zUnwJo) `5... foo.dev.koding.com` if you want to develop teams product. The first part, `5...` is the ip address of your VM. The second part `foo` is the name of the team.

## Day to day workflow

* Pull latest code from upstream: `git pull --rebase <upstream> <branch>`
* Update any changed config: `./configure`
* Start/rebuild required services, i.e. databases: `./run buildservices`
* Start the workers: `./run backend`

## kd

To connect your Koding VMs to your local IDE, we’ll use a command line program called: `kd` To get started, login to https://team.koding.com/Channels/team and click on http://take.ms/rB1Jm to get link to download kd.

Currently only OSX and Linux are supported. Once it's done installing, `kd` should be available in your path and you can do `kd -h` to see list of help topics.

* Do `kd list` to see list of your vms.
* Do `kd mount <machine name> <local folder> --remotepath “/home/<username>/koding”` to mount your remote koding to your local folder. Remote path needs to be a full path to the folder on your VM.
* Do `kd ssh <machine name>` to ssh into the machine. It's recommend you do operations like `git`, `./run backend` in ssh window.

## Known limitations

* Recursive file read commands like `find -r`, or `ag` will take a long time to complete due to network roundtrip. Use `kd ssh` instead.
* Any changes you make on your remote won't be visible on your local until you remount.
* In case of fire unmount and mount your machine. In worst case scenarios, do `sudo kd restart` to restart kd.
* This is a BETA software, so here be bugs. Open a bug report and they'll all be fixed.
