// Package main provides errors plugin for gene package
package main

import (
	"github.com/cihangir/gene/generators/common"
	gerrors "github.com/cihangir/gene/generators/errors"
	"github.com/hashicorp/go-plugin"
)

func main() {
	plugin.Serve(&plugin.ServeConfig{
		HandshakeConfig: common.HandshakeConfig,
		Plugins: map[string]plugin.Plugin{
			"generate": common.NewGeneratorPlugin(&gerrors.Generator{}),
		},
	})
}
