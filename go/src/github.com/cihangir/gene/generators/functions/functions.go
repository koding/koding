// Package functions generate functions for gene package system
package functions

import (
	"fmt"
	"strings"

	"github.com/cihangir/gene/generators/common"
)

// Generator for functions
type Generator struct{}

func pathfunc(data *common.TemplateData) string {
	return fmt.Sprintf(
		"%s%s/api/%s.go",
		data.Settings.Get("fullPathPrefix").(string),
		data.ModuleName,
		strings.ToLower(data.Schema.Title),
	)
}

// Generate generates and writes the functions of the schema
func (g *Generator) Generate(req *common.Req, res *common.Res) error {
	o := &common.Op{
		Name:         "functions",
		Template:     FunctionsTemplate,
		PathFunc:     pathfunc,
		FormatSource: true,
	}

	return common.Proces(o, req, res)
}
