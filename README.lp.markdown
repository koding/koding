Local Provisioning devenv
=========================

# Flow overview

![flow](http://i.imgur.com/6jqrNs2.png)

# Prerequisites

## User, team and klient

A user and a team are going to be required, if you don't have any in your MongoDB created them first.

Username and team are used with kloudctl when asking kloud to perform team actions, like apply, auth or plan.

## ./run backend

## Building kloudctl

Install the kloudctl tool with:

```
$ go install koding/kites/kloud/kloudctl
```

Commands going to be used:

- [kloudctl kontrol](./go/src/kites/kloud/kloudctl/README.md#kontrol)
- [kloudctl team](./go/src/kites/kloud/kloudctl/README.md#team)
- [kloudctl vagrant](./go/src/kites/kloud/kloudctl/README.md#vagrant)
- [route53](./go/src/kites/kloud/scripts/route53/README.md)

## Building klient

Build steps:

```bash
$ cd go/src/koding/klient
$ cat >Makefile.dev <<EOF
all:
        @echo "\033[0;32m==> Building all packages\033[0m"
        @go build -v -ldflags "-X koding/klient/protocol.Version 1.0.99 -X koding/klient/protocol.Environment development"

.PHONY: all
EOF
$ make -f Makefile.dev
```

Generate a kite.key and Start the client:

```bash
$ kloudctl kontrol key -u rafal -o kite.key
$ KITE_HOME=$PWD ./klient -kontrol-url http://koding-${USER}.ngrok.com/kontrol/kite -tunnel-server tunnel.dev.koding.io:8081
...
2016-02-04 15:42:39 [klient] INFO     Using version: '1.0.99' querystring: 'da38a55e-5422-4ab4-a319-096cd1e88866'
```

Verify the klient is registered to your kontrol:

```bash
$ kloudctl kontrol list | jq
[
...
  {
    "name": "klient",
    "username": "rafal",
    "id": "da38a55e-5422-4ab4-a319-096cd1e88866",
    "environment": "development",
    "region": "public-region",
    "version": "1.0.99",
    "hostname": "rjeczalik-osxpro.local",
    "url": "http://rafal.tunnel.dev.koding.io:8081/klient/kite",
    "concurrent": true,
    "kontrolURL": "http://127.0.0.1:3000/kite",
    "kontrolUser": "koding",
    "authType": "token"
  },
...
]
```

Verify the klient serves vagrant requests:

```bash
$ kloudctl vagrant version -host da38a55e-5422-4ab4-a319-096cd1e88866
1.7.4
```

**NOTE**: Route53 takes a while to propagate DNS entries, if you want to see the progress pass `-debug` flag to the client.

## (optionally) Building tunnelserver

If for whatever reason `tunnel.dev.koding.io:8081` is down or you want to use your own for development, build it with:

```bash
$ go install koding/kites/cmd/tunnelserver
```

And start it with:

```
$ cat >tunnelserver.sh <<EOF
#!/bin/bash

export DOMAIN="mytunnel.dev.koding.io" \
	PUBLIC_IP="104.155.84.135" \
	PORT="8081" \
	KITE_KONTROL_URL="http://koding-rjeczalik.ngrok.com/kontrol/kite"

$HOME/bin/tunnelserver \
        -basevirtualhost "${DOMAIN}:${PORT}" \
        -hostedzone dev.koding.io \
        -accesskey "${AWS_ACCESS_KEY}" \
        -secretkey "${AWS_SECRET_KEY} \\
        -serveraddr "${PUBLIC_IP}:${PORT}" \
        -region "unknown" -port "${PORT}" \
        -environment development
EOF
$ chmod +x tunnelserver.sh
```
```bash
$ ./tunnelserver.sh
2016-02-04 15:01:07 [tunnelserver] INFO     Dialing 'kontrol' kite: http://koding-rjeczalik.ngrok.com/kontrol/kite
2016-02-04 15:01:07 [tunnelserver] INFO     Connected to Kontrol
2016-02-04 15:01:07 [tunnelserver] INFO     Registering to kontrol with URL: http://104.155.84.135:8081/tunnelkite-0.0.1/kite
2016-02-04 15:01:08 [tunnelserver] INFO     Registered to kontrol with URL: http://104.155.84.135:8081/tunnelkite-0.0.1/kite and Kite query: /koding/development/tunnelkite/0.0.1/unknown/koding-vm/3813c4bc-33a2-4219-b7e7-fc31d3237148
2016-02-04 15:01:08 [tunnelserver] INFO     New listening: 0.0.0.0:8081
2016-02-04 15:01:08 [tunnelserver] INFO     Serving...
```

# Getting started

### Creating vagrant stack

Prepare Vagrant template:

```bash
$ export TEAM_USER=rafal
$ cat >vagrant.json <<EOF
{
    "resource": {
        "vagrantkite_build": {
            "example_1": {
                "cpus": 2,
                "memory": 2048,
                "customScript": "sudo apt-get install sl -y\ntouch /tmp/${var.koding_user_username}.txt",

                "registerURL": "http://example1.${TEAM_USER}.tunnel.dev.koding.io:8081/klient/kite",
                "kontrolURL": "http://koding-${USER}.ngrok.com/kontrol/kite",
                "klientURL": "https://s3-eu-west-1.amazonaws.com/kodingdev-klient/klient_0.1.99_development_amd64.deb"
            }
        }
    }
}
EOF
```

The `registerURL`, `kontrolURL` and `klientURL` fields are not going to be needed in production, as those value will be default ones.

Create jComputeStack for your existing team:

```bash
$ cat vagrant.json | kloudctl team init -u rafal -team foobar -klient da38a55e-5422-4ab4-a319-096cd1e88866 > stack.json
```

Verify the kloud can connect to your klient:

```bash
$ $(cat stack.json | jq -r .kloudctl.auth)
authenticate raw response: {"56b36a7cb07390b5c6e4dbd4":true}
```

And finally build the stack:

```bash
$ $(cat stack.json | jq -r .kloudctl.apply)
{EventId:apply-56b36ef1b07390ecc4e84937}
2016-02-04 16:32:04 ==> apply started [Status: Building Percentage: 0]
2016-02-04 16:32:08 ==> Fetching and validating credentials [Status: Building Percentage: 30]
2016-02-04 16:32:12 ==> Building stack resources [Status: Building Percentage: 50]
2016-02-04 16:32:16 ==> Building stack resources [Status: Building Percentage: 55]
2016-02-04 16:32:20 ==> Building stack resources [Status: Building Percentage: 60]
...
```

Verify, upon successful build, the klient from inside of vagrant has registered to kontrol with the `registerURL` passed in the template:

```
$ kloudctl kontrol list | jq
[
...
  {
    "name": "klient",
    "username": "rafal",
    "id": "f5e4c605-b5ca-400a-8158-5274126f772c",
    "environment": "development",
    "region": "public-region",
    "version": "0.1.99",
    "hostname": "rafal",
    "url": "http://example1.rafal.tunnel.dev.koding.io:8081/klient/kite",
    "concurrent": true,
    "kontrolURL": "http://127.0.0.1:3000/kite",
    "kontrolUser": "koding",
    "authType": "token"
  },
...
]
```
