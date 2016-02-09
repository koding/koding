package main

import (
	"koding/kites/terraformplugins/vagrant"

	"github.com/hashicorp/terraform/plugin"
)

func init() {
	vagrant.Version = "0.0.1"
	vagrant.Name = "vagrant"
	vagrant.Environment = "terraform"
	vagrant.Region = "terraform"
}

func main() {
	plugin.Serve(&plugin.ServeOpts{
		ProviderFunc: vagrant.Provider,
	})
}
