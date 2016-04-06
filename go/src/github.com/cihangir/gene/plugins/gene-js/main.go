// Package main provides kit plugin for gene package
package main

import (
	"github.com/cihangir/gene/generators/common"
	gjs "github.com/cihangir/gene/generators/js"
	plugin "github.com/hashicorp/go-plugin"
)

func main() {
	plugin.Serve(&plugin.ServeConfig{
		HandshakeConfig: common.HandshakeConfig,
		Plugins: map[string]plugin.Plugin{
			"generate": common.NewGeneratorPlugin(&gjs.Generator{}),
		},
	})
}
