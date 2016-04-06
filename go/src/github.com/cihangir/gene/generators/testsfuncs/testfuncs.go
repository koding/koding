// Package testsfuncs generate basic test helper functions
package testsfuncs

import (
	"fmt"

	"github.com/cihangir/gene/generators/common"
)

// Generator for tests
type Generator struct{}

func pathfunc(data *common.TemplateData) string {
	return fmt.Sprintf(
		"%stests/testfuncs.go",
		data.Settings.Get("fullPathPrefix").(string),
	)
}

// Generate generates Dockerfile for given schema
func (g *Generator) Generate(req *common.Req, res *common.Res) error {
	o := &common.Op{
		Name:         "tests-funcs",
		Template:     TestFuncs,
		PathFunc:     pathfunc,
		FormatSource: true,
	}

	return common.Proces(o, req, res)
}
