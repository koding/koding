# Vagrantutil [![GoDoc](http://img.shields.io/badge/go-documentation-blue.svg?style=flat-square)](http://godoc.org/github.com/koding/vagrantutil) 

Vagrantutil is a toolset for managing Vagrant boxes via an idiomatic Go
(Golang) API. The package is work in progress, so please vendor it. Checkout
the examples below for the usage.

## Install

```bash
go get github.com/koding/vagrantutil
```

## Usage and Examples

```go
package main

import (
	"log"

	"github.com/koding/vagrantutil"
)

func main() {
	vagrant, _ := vagrantutil.NewVagrant("myfolder")

	vagrant.Create(`# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.hostname = "vagrant"

  config.vm.provider "virtualbox" do |vb|
    # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, "--memory", "2048", "--cpus", "2"]
  end
end
`)

	status, _ := vagrant.Status() // prints "NotCreated"

	// starts the box
	output, _ := vagrant.Up()

	// print the output
	for line := range output {
		log.Println(line)
	}

	// stop/halt the box
	vagrant.Halt()

	// destroy the box
	vagrant.Destroy()
}
```
