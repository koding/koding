// Package main provides models plugin for gene package
package main

import (
	"github.com/cihangir/gene/generators/common"
	gmodels "github.com/cihangir/gene/generators/models"
	"github.com/hashicorp/go-plugin"
)

func main() {
	plugin.Serve(&plugin.ServeConfig{
		HandshakeConfig: common.HandshakeConfig,
		Plugins: map[string]plugin.Plugin{
			"generate": common.NewGeneratorPlugin(&gmodels.Generator{}),
		},
	})
}
