// Package rows provides Json-schema based database rows to arbitrary struct
// scanner generation
package generows

import (
	"fmt"
	"strings"

	"github.com/cihangir/gene/generators/common"
)

type Generator struct{}

func pathfunc(data *common.TemplateData) string {
	return fmt.Sprintf(
		"%s%s_rowscanner.go",
		data.Settings.Get("fullPathPrefix").(string),
		strings.ToLower(data.Schema.Title),
	)

}

// Generate generates and writes the errors of the schema
func (g *Generator) Generate(req *common.Req, res *common.Res) error {
	o := &common.Op{
		Name:         "rows",
		Template:     RowScannerTemplate,
		PathFunc:     pathfunc,
		FormatSource: true,
	}

	return common.Proces(o, req, res)
}
