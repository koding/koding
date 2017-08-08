package main

import (
	"github.com/hashicorp/terraform/builtin/providers/vault"
	"github.com/hashicorp/terraform/plugin"
)

func main() {
	plugin.Serve(&plugin.ServeOpts{
		ProviderFunc: vault.Provider,
	})
}
