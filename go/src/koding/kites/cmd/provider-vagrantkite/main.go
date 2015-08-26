package main

import (
	"koding/kites/terraformplugins/vagrantkite"

	"github.com/hashicorp/terraform/plugin"
)

func main() {
	plugin.Serve(&plugin.ServeOpts{
		ProviderFunc: vagrantkite.Provider,
	})
}
