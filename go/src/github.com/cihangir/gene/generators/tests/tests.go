// Package tests creates tests files for the given schema
package tests

import (
	"fmt"
	"log"
	"strings"

	"github.com/cihangir/gene/generators/common"
)

// Generator generates the tests
type Generator struct{}

func pathfunc(data *common.TemplateData) string {
	return fmt.Sprintf(
		"%sworkers/%s/tests/%s_test.go",
		data.Settings.Get("fullPathPrefix").(string),
		data.ModuleName,
		strings.ToLower(data.Schema.Title),
	)
}

// Generate generates the tests for the schema
func (g *Generator) Generate(req *common.Req, res *common.Res) error {
	p, err := common.Discover("gene-tests-*")
	if err != nil {
		log.Fatalf("err %s", err.Error())
	}
	defer p.Shutdown()

	o := &common.Op{
		Name:         "tests",
		Template:     TestsTemplate,
		PathFunc:     pathfunc,
		FormatSource: true,
	}

	return common.Proces(o, req, res)
}
