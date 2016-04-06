// Package errors generates the common errors for the modules
package errors

import (
	"fmt"
	"strings"

	"github.com/cihangir/gene/generators/common"
)

// Generator for errors
type Generator struct{}

func pathfunc(data *common.TemplateData) string {
	return fmt.Sprintf(
		"%s/%s.go",
		data.Settings.Get("fullPathPrefix").(string),
		strings.ToLower(data.Schema.Title),
	)
}

// Generate generates and writes the errors of the schema
func (g *Generator) Generate(req *common.Req, res *common.Res) error {
	o := &common.Op{
		Name:     "errors",
		Template: ErrorsTemplate,
		PathFunc: pathfunc,
		Clear:    true,
	}

	return common.Proces(o, req, res)
}
