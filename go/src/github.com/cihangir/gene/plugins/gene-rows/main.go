// Package main provides rows plugin for gene package
package main

import (
	"github.com/cihangir/gene/generators/common"
	grows "github.com/cihangir/generows"
	"github.com/hashicorp/go-plugin"
)

func main() {
	plugin.Serve(&plugin.ServeConfig{
		HandshakeConfig: common.HandshakeConfig,
		Plugins: map[string]plugin.Plugin{
			"generate": common.NewGeneratorPlugin(&grows.Generator{}),
		},
	})
}
