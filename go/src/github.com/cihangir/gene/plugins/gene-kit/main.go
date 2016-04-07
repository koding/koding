// Package main provides kit plugin for gene package
package main

import (
	"github.com/cihangir/gene/generators/common"
	gkit "github.com/cihangir/gene/generators/kit"
	"github.com/hashicorp/go-plugin"
)

func main() {
	plugin.Serve(&plugin.ServeConfig{
		HandshakeConfig: common.HandshakeConfig,
		Plugins: map[string]plugin.Plugin{
			"generate": common.NewGeneratorPlugin(&gkit.Generator{}),
		},
	})
}
