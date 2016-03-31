// Package clients generates clients for the generated api
package clients

import (
	"bytes"
	"fmt"
	"text/template"

	"go/format"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

type Generator struct{}

// Generate generates the client package for given schema
func (c *Generator) Generate(context *common.Context, s *schema.Schema) ([]common.Output, error) {
	tmpl := template.New("clients.tmpl").Funcs(context.TemplateFuncs)
	if _, err := tmpl.Parse(ClientsTemplate); err != nil {
		return nil, err
	}

	moduleName := context.ModuleNameFunc(s.Title)
	outputs := make([]common.Output, 0)

	for _, def := range common.SortedObjectSchemas(s.Definitions) {

		var buf bytes.Buffer

		data := struct {
			ModuleName string
			Schema     *schema.Schema
		}{
			ModuleName: moduleName,
			Schema:     def,
		}

		if err := tmpl.Execute(&buf, data); err != nil {
			return nil, err
		}

		f, err := format.Source(buf.Bytes())
		if err != nil {
			return nil, err
		}

		path := fmt.Sprintf(
			"%s%s/clients/%s.go",
			context.Config.Target,
			moduleName,
			context.FileNameFunc(def.Title),
		)

		outputs = append(outputs, common.Output{Content: f, Path: path})
	}

	return outputs, nil
}
