## Dockerized Koding Golang Development

### Build

```
$ cd koding/go
$ docker build -t koding/go --force-rm .
```

### Run

```
$ docker run \
  --name development \
  --rm \
  -it \
  -v ~/koding:/opt/koding \
  koding/go
```

> Note: Notice how your local Koding repo gets mounted
> in the form of a host volume into `/opt/koding` inside
> the container at runtime.
