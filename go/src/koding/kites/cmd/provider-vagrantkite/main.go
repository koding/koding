package main

import (
	"koding/kites/terraformplugins/vagrantkite"

	"github.com/hashicorp/terraform/plugin"
)

func init() {
	vagrantkite.Version = "0.0.1"
	vagrantkite.Name = "vagrantkite"
	vagrantkite.Environment = "terraform"
	vagrantkite.Region = "terraform"
}

func main() {
	plugin.Serve(&plugin.ServeOpts{
		ProviderFunc: vagrantkite.Provider,
	})
}
