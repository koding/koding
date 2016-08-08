package main

import (
	"github.com/hashicorp/terraform/builtin/providers/ultradns"
	"github.com/hashicorp/terraform/plugin"
)

func main() {
	plugin.Serve(&plugin.ServeOpts{
		ProviderFunc: ultradns.Provider,
	})
}
