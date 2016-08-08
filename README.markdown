# Koding

[![Slack Status](http://cebeci.koding.com/slackin/badge.svg)](https://cebeci.koding.com/slackin/)
[![Docker Pulls](https://img.shields.io/docker/pulls/koding/koding.svg?maxAge=2592000)](https://hub.docker.com/r/koding/koding/)

The Simplest Way to Manage Your Entire Dev Infrastructure!

Koding is a development platform that provides a manner for you to build up your
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

Then you will be able to access Koding UI via port `8090` (e.g. [localhost:8090](http://localhost:8090)) on your host.

## Run Koding on Koding.com

Yes, you can run koding on [koding.com](https://www.koding.com) by using
the provided [.koding.yml](https://github.com/koding/koding/blob/master/.koding.yml)

For more information about stacks: [koding.com/docs](https://www.koding.com/docs/creating-an-aws-stack)

## Getting started for Development

If you wish to work on Koding itself, you need to install following software
packages:

### Software Requirements

- [git](https://git-scm.com)
- [docker](https://www.docker.com)
- [docker-compose](https://www.docker.com/products/docker-compose)

### Start developing

You can run docker-compose environment for developing koding by
executing commands in the following snippet.

```bash
git clone https://github.com/koding/koding.git
cd koding
docker-compose up
```

Now you can navigate to http://localhost:8090 to see your local Koding
instance. Enjoy!

docker-compose will attach working tree to `/opt/koding` in backend
service container.  Changes in edited files will be visible in the
runtime environment.

You will need to run client builder to see your changes in built
frontend code. This can be achieved with command below.

```bash
docker exec koding_backend_1 make -C /opt/koding/client
```

If you need to execute some commands by yourself in runtime
environment then you can use following snippet to start a shell in
backend service container.

```bash
docker exec -it koding_backend_1 bash
```

You can follow [coffeescript-styleguide](https://github.com/koding/styleguide-coffeescript)
that we are relying on.

## License

Koding is licensed under [Apache 2.0](https://github.com/koding/koding/blob/master/LICENSE).

## Contribute

The main purpose of this repository to continue evolve Koding in order to make it more
stable and create the best development experience ever. If you're interested
in helping with that, please check our [open
issues](https://github.com/koding/koding/issues). You can also join the
conversation in our [slack team]!

[slack team]: http://cebeci.koding.com/slackin/
