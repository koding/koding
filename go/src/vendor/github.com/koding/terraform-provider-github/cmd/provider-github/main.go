package main

import (
	"github.com/hashicorp/terraform/plugin"
	github "github.com/koding/terraform-provider-github"
)

func main() {
	plugin.Serve(&plugin.ServeOpts{
		ProviderFunc: github.Provider,
	})
}
