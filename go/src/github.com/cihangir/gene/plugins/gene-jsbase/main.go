// Package main provides jsbase plugin for gene package
package main

import (
	"github.com/cihangir/gene/generators/common"
	gjsbase "github.com/cihangir/gene/generators/jsbase"
	plugin "github.com/hashicorp/go-plugin"
)

func main() {
	plugin.Serve(&plugin.ServeConfig{
		HandshakeConfig: common.HandshakeConfig,
		Plugins: map[string]plugin.Plugin{
			"generate": common.NewGeneratorPlugin(&gjsbase.Generator{}),
		},
	})
}
