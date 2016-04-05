// Package main provides ddl plugin for gene package
package main

import (
	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/geneddl"
	"github.com/hashicorp/go-plugin"
)

func main() {
	plugin.Serve(&plugin.ServeConfig{
		HandshakeConfig: common.HandshakeConfig,
		Plugins: map[string]plugin.Plugin{
			"generate": common.NewGeneratorPlugin(&geneddl.Generator{}),
		},
	})
}
