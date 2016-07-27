# Koding

[![Gitter](https://img.shields.io/gitter/room/koding/koding.svg?maxAge=2592000)](https://gitter.im/koding)
[![#koding on Freenode](https://img.shields.io/badge/koding-on%20freenode-brightgreen.svg?maxAge=2592000)]()
[![Docker Pulls](https://img.shields.io/docker/pulls/koding/koding.svg?maxAge=2592000)](https://hub.docker.com/r/koding/koding/)

The Simplest Way to Manage Your Entire Dev Infrastructure!

Koding is a development platform that provides you to build up your
environment from scratch. Developers get everything they need to spin up
full-stack, project-specific environments in seconds. Share them, update them,
and manage infrastructure from a simple interface.

You can try Koding now on [koding.com](https://www.koding.com)

## Quick Start with Docker

Koding can be run as a docker container, it requires `docker-compose` which
you can install from [here](https://docs.docker.com/compose/install/). For the
rest you can follow these steps:

```bash
git clone https://github.com/koding/docker-compose.git koding-docker-compose
cd koding-docker-compose
docker-compose up -d
```

## Run Koding on Koding.com

Yes, you can run koding on [koding.com](https://www.koding.com) by using
provided [.koding.yml](https://github.com/koding/koding/blob/master/.koding.yml)

For mor information about stacks: [koding.com/docs](https://www.koding.com/docs/creating-an-aws-stack)

## Getting started for Development

If you wish to work on Koding itself, you need to install following software
packages:

### Software Requirements

- [Golang](http://www.golang.org/) v1.4
- [Node.js](https://nodejs.org/en/) v0.10
- [Coffeescript](http://coffeescript.org/)
- [Supervisord](http://supervisord.org/)

### Start developing

If you have the above software packages installed on your computer, you can
follow steps for running the instance:

```bash
git clone https://github.com/koding/koding.git /your/koding/path
cd /your/koding/path
node -v # make sure your node version is not greater than `0.10.x`
coffee -v # make sure this doesn't return an error
npm install
```

You should have packages ready for running build specific scripts.

```bash
cd /your/koding/path
./configure # create necessary config files
./run install # start to install dependencies
./run buildservices # build the services
./run # run all services
```

As a result of this, you will have a file watcher watching your backend files
(both node, and golang) and restart services when it's necessary. Now open up
another terminal and run the following commands:

```bash
cd /your/koding/path
cd client # move into frontend client folder
npm install # install client dependencies
make # this will run a client watcher for you
```

Right now you should have 2 different watchers for (1) your backend files, (2)
for your frontend client files.

Now you can navigate to [](http://localhost:8090) to see your local Koding
instance. Enjoy!

You can follow [coffeescript-styleguide](https://github.com/koding/styleguide-coffeescript)
that we are relying on.

## License

Koding is licensed under [Apache 2.0](https://github.com/koding/koding/blob/master/LICENSE).

## Contribute

The main purpose of this repository to continue evolve Koding, making it more
stable and create the best development experience ever. If you're interested
in helping with that, please check our [open
issues](https://github.com/koding/koding/issues).
