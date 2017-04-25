## Local

Be sure the repo is inside a `$GOPATH`
To build and test all packages run:

`make`

Development builds will have the version `0.0.1`. To confirm please run:

```sh
$ ./klient --version
0.0.1
```

## Docker

### Build

First build the `koding/go` Docker image

```sh
$ cd go/
$ docker build --force-rm -t koding/go .
```

```sh
$ docker run --rm \
    -it \
    -v ~/koding:/opt/koding \
    koding/go

root@8a39fe87816f:/opt/koding# cd go/src/koding/klient && make build
root@8a39fe87816f:/opt/koding# exit
```

```sh
$ cd src/koding/klient
$ docker build --force-rm -t koding/klient .
```

### Run

```sh
$ docker run --name klient \
    -d \
    -p 8000:8000 \
    -e TOKEN=${TOKEN} \
    koding/klient /opt/kite/klient/entrypoint.sh
```

or

```sh
$ docker run --name klient \
    -d \
    -p 8000:8000 \
    -e KONTROL=https://koding.com/kontrol/kite \
    -e TOKEN=${TOKEN} \
    koding/klient bash -c '\
        klient \
            -debug \
            -kontrol-url $KONTROL \
            -register \
            -port $PORT \
            -token $TOKEN; \
        klient \
            -kontrol-url $KONTROL \
            -port $PORT
    '
```
