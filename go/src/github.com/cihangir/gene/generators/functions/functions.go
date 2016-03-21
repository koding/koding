package functions

import (
	"bytes"
	"fmt"
	"strings"
	"text/template"

	"go/format"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

type Generator struct{}

// Generate generates and writes the errors of the schema
func (g *Generator) Generate(context *common.Context, s *schema.Schema) ([]common.Output, error) {
	temp := template.New("constructors.tmpl").Funcs(context.TemplateFuncs)
	if _, err := temp.Parse(FunctionsTemplate); err != nil {
		return nil, err
	}

	moduleName := context.ModuleNameFunc(s.Title)

	outputs := make([]common.Output, 0)

	for _, def := range common.SortedObjectSchemas(s.Definitions) {

		data := struct {
			ModuleName string
			Schema     *schema.Schema
		}{
			ModuleName: moduleName,
			Schema:     def,
		}

		var buf bytes.Buffer

		if err := temp.ExecuteTemplate(&buf, "constructors.tmpl", data); err != nil {
			return nil, err
		}

		path := fmt.Sprintf(
			"%s%s/api/%s.go",
			context.Config.Target,
			moduleName,
			strings.ToLower(s.Title),
		)

		api, err := format.Source(buf.Bytes())
		if err != nil {
			return nil, err
		}

		outputs = append(outputs, common.Output{
			Content: api,
			Path:    path,
		})
	}

	return outputs, nil
}
