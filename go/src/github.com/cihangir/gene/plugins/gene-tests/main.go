// Package main provides tests plugin for gene package
package main

import (
	"github.com/cihangir/gene/generators/common"
	gtests "github.com/cihangir/gene/generators/tests"
	"github.com/hashicorp/go-plugin"
)

func main() {
	plugin.Serve(&plugin.ServeConfig{
		HandshakeConfig: common.HandshakeConfig,
		Plugins: map[string]plugin.Plugin{
			"generate": common.NewGeneratorPlugin(&gtests.Generator{}),
		},
	})
}
