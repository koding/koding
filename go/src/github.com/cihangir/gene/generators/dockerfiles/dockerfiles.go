// Package dockerfiles generate docker file stubs
package dockerfiles

import (
	"fmt"
	"strings"

	"github.com/cihangir/gene/generators/common"
)

// Generator for dockerfiles
type Generator struct{}

func pathfunc(data *common.TemplateData) string {
	return fmt.Sprintf(
		"%s/%s/Dockerfile",
		data.Settings.Get("fullPathPrefix").(string),
		strings.ToLower(data.Schema.Title),
	)
}

// Generate generates Dockerfile for given schema
func (g *Generator) Generate(req *common.Req, res *common.Res) error {
	o := &common.Op{
		Name:        "dockerfiles",
		Template:    DockerfileTemplate,
		PathFunc:    pathfunc,
		DoNotFormat: true,
	}

	return common.Proces(o, req, res)
}
