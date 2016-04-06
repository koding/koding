// Package main provides dockerfiles plugin for gene package
package main

import (
	"github.com/cihangir/gene/generators/common"
	gdockerfiles "github.com/cihangir/gene/generators/dockerfiles"
	"github.com/hashicorp/go-plugin"
)

func main() {
	plugin.Serve(&plugin.ServeConfig{
		HandshakeConfig: common.HandshakeConfig,
		Plugins: map[string]plugin.Plugin{
			"generate": common.NewGeneratorPlugin(&gdockerfiles.Generator{}),
		},
	})
}
