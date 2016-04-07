package jsbase

import (
	"fmt"

	"github.com/cihangir/gene/generators/common"
)

// Generator for js client
type Generator struct{}

func pathfunc(fileName string) func(data *common.TemplateData) string {
	return func(data *common.TemplateData) string {
		return fmt.Sprintf(
			"%s/%s/%s.js",
			data.Settings.Get("fullPathPrefix").(string),
			data.ModuleName,
			fileName,
		)
	}
}

// Generate generates JS client for given schema
func (g *Generator) Generate(req *common.Req, res *common.Res) error {
	o := &common.Op{
		Name:           "js",
		Template:       IndexTemplate,
		PathFunc:       pathfunc("index"),
		DoNotFormat:    true,
		RemoveNewLines: true,
	}

	if err := common.ProcesRoot(o, req, res); err != nil {
		return err
	}

	o = &common.Op{
		Name:           "js",
		Template:       RequestTemplate,
		PathFunc:       pathfunc("_request"),
		DoNotFormat:    true,
		RemoveNewLines: true,
	}

	if err := common.ProcesRoot(o, req, res); err != nil {
		return err
	}

	return nil
}
