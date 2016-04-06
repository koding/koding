// Package main provides testsfuncs funcs plugin for gene package
package main

import (
	"github.com/cihangir/gene/generators/common"
	gtestsfuncs "github.com/cihangir/gene/generators/testsfuncs"
	"github.com/hashicorp/go-plugin"
)

func main() {
	plugin.Serve(&plugin.ServeConfig{
		HandshakeConfig: common.HandshakeConfig,
		Plugins: map[string]plugin.Plugin{
			"generate": common.NewGeneratorPlugin(&gtestsfuncs.Generator{}),
		},
	})
}
