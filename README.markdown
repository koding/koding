# Koding

[![Docker Pulls](https://img.shields.io/docker/pulls/koding/koding.svg?maxAge=2592000)](https://hub.docker.com/r/koding/koding/)

The Simplest Way to Manage Your Entire Dev Infrastructure!

Koding is a development platform that orchestrates your dev
environment. Developers get everything they need to spin up
full-stack, project-specific environments in seconds. Share them, update them,
and manage infrastructure from a simple interface.

You can try Koding now on [koding.com](https://www.koding.com)

## Quick Start with Docker-Compose

Easiest way to run Koding is to install `docker-compose` which
can be found [here](https://docs.docker.com/compose/install/). For the
rest you can follow these steps:

```bash
git clone https://github.com/koding/docker-compose.git koding-docker-compose
cd koding-docker-compose
# Requires docker-compose version >= 1.6
docker-compose up -d
```

Now you are able to access Koding via port `8090` (e.g. [localhost:8090](http://localhost:8090)) on your host.

## Run Koding on Koding.com

Yes, you can run koding on [koding.com](https://www.koding.com) by using
the provided [.koding.yml](https://github.com/koding/koding/blob/master/.koding.yml)

For more information about stacks: [koding.com/docs](https://www.koding.com/docs/creating-an-aws-stack)

## Getting started for Development

You need to install following software packages to run Koding:

- [git](https://git-scm.com)
- [docker](https://www.docker.com)
- [docker-compose](https://www.docker.com/products/docker-compose)

### Start developing

You are now ready to run Koding.

```bash
git clone https://github.com/koding/koding.git
cd koding
docker-compose -f docker-compose-init.yml run init
docker-compose up
```

If you don't have a powerful computer, this may take a while at first, slow computers may take up to 15 minutes before they build the entire system. Please be patient. Once it is up and running, everything will be smooth and very fast.

Now you can navigate to http://localhost:8090 to see your local Koding
instance. Enjoy! (If you don't see it, keep waiting, it will show up)

When you edit files on your host computer, they will be visible in the
runtime environment. Watchers will automatically restart backend workers, re-compile frontend code. You don't need to do anything for it.

### Tips

If you need to execute some commands in runtime
environment, here is how you can start a shell in
backend service container:

```bash
docker-compose exec backend bash
```

You can follow [coffeescript-styleguide](https://github.com/koding/styleguide-coffeescript)
that we are relying on.

## Running Koding on Local Machine

This is if you don't want to do docker-compose way and install everything locally, (not recommended).

### Software Prerequisites

- [Go](http://www.golang.org/) v1.7
- [Node.js](https://nodejs.org/en/) v0.10
- [CoffeeScript](http://coffeescript.org/) v1.8.0
- [Supervisor](http://supervisord.org/)

### Start developing

Follow these steps for running the instance:

```bash
git clone https://github.com/koding/koding.git /your/koding/path
cd /your/koding/path
node -v # make sure your node version is not greater than `0.10.x`
npm -v # make sure your npm version is 2.15.x
coffee -v # make sure your coffeeScript version must be 1.8
npm install
```

You should have packages ready for running build specific scripts.

```bash
./configure # create necessary config files
./run install # start to install dependencies
./run buildservices # build the services
./run # run all services
```

As a result, you will have a file watcher watching your backend files
(both node, and golang) and restart services when it's necessary. Now open up
another terminal and run following commands:

```bash
cd /your/koding/path
cd client # move into frontend client folder
npm install # install client dependencies
make # this will run a client watcher for you
```

Right now you should have 2 different watchers for (1) your backend files,
(2)for your frontend client files.
Now you can navigate to [](http://localhost:8090) to see your local Koding
instance. Enjoy!

## License

This repository is licensed under [GNU AGPL V3](https://github.com/koding/koding/blob/master/LICENSE)
Koding Community Edition is licensed under [Apache 2.0](https://github.com/koding-ce/koding)

## Contribute

The main purpose of this repository to continue evolve Koding in order to make it more
stable and create the best development experience ever. If you're interested
in helping with that, please check our [open
issues](https://github.com/koding/koding/issues). You can also join the
conversation in our [slack team]!

[slack team]: http://cebeci.koding.com/slackin/
