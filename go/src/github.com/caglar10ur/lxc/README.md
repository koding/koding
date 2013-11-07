# Go Bindings for LXC (Linux Containers)

This package implements [Go](http://golang.org) bindings for the [LXC](http://linuxcontainers.org/) C API.

## Requirements

This package requires [LXC 0.9+](https://github.com/lxc/lxc/releases) and [Go 1.x](https://code.google.com/p/go/downloads/list).

It has been tested on 

+ Ubuntu 12.10 (quantal) by manually installing LXC 0.9 
+ Ubuntu 13.04 (raring) by using distribution [provided packages](https://launchpad.net/ubuntu/raring/+package/lxc)
+ Ubuntu 13.10 (saucy) by using distribution [provided packages](https://launchpad.net/ubuntu/saucy/+package/lxc)

## Installing

The typical `go get github.com/caglar10ur/lxc` will install LXC Go Bindings.

## Documentation

Documentation can be found at [GoDoc](http://godoc.org/github.com/caglar10ur/lxc)

## Examples

See the [examples](https://github.com/caglar10ur/lxc/tree/master/examples) directory for some.

## Notes

Note that as we don’t have full user namespaces support at the moment, any code using the LXC API needs to run as root.

Also please be aware that LXC C API is not considered stable until LXC 1.0 release. Development branch (see below) is currently **under heavy development with incompatible changes** and will be merged to master once LXC 1.0 released.

## Contributing

We'd love to see LXC improve to contribute to it;

* **Fork** the repository
* **Modify** your fork
* Ensure your fork **passes all tests**
* **Send** a pull request
	* Bonus points if the pull request includes *what* you changed, *why* you changed it, and *tests* attached.
	* For the love of all that is holy, please use `go fmt` *before* you send the pull request.

We'll review it and merge it in if it's appropriate.

## Development branch

If you are interested with upcoming LXC version (staging tree) then please use the **devel** branch.
