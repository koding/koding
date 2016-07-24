package main

import (
	"github.com/hashicorp/terraform/builtin/providers/digitalocean"
	"github.com/hashicorp/terraform/plugin"
)

func main() {
	plugin.Serve(&plugin.ServeOpts{
		ProviderFunc: digitalocean.Provider,
	})
}
