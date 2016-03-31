package kit

import (
	"bytes"
	"fmt"
	"strings"
	"text/template"

	"go/format"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

///
/// metric - implement dogstatsd
/// throttling - implement one with shared backend
/// logging - leveled - filtered
///
///
///
type Generator struct{}

// Generate generates and writes the errors of the schema
func (g *Generator) Generate(context *common.Context, s *schema.Schema) ([]common.Output, error) {
	outputs, err := GenerateKitWorker(context, s)
	if err != nil {
		return nil, err
	}

	output, err := GenerateInterface(context, s)
	if err != nil {
		return nil, err
	}

	outputs = append(outputs, output...)

	output, err = GenerateTransportHTTPSemiotics(context, s)
	if err != nil {
		return nil, err
	}
	outputs = append(outputs, output...)

	output, err = GenerateTransportHTTPServer(context, s)
	if err != nil {
		return nil, err
	}

	outputs = append(outputs, output...)

	output, err = GenerateTransportHTTPClient(context, s)
	if err != nil {
		return nil, err
	}

	outputs = append(outputs, output...)

	output, err = GenerateService(context, s)
	if err != nil {
		return nil, err
	}
	outputs = append(outputs, output...)

	return outputs, nil
}

func generate(context *common.Context, s *schema.Schema, templ string, sectionName string) ([]common.Output, error) {
	temp := template.New("kit.tmpl").Funcs(context.TemplateFuncs)
	if _, err := temp.Parse(templ); err != nil {
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

		if err := temp.ExecuteTemplate(&buf, "kit.tmpl", data); err != nil {
			return nil, err
		}

		path := fmt.Sprintf(
			"%s/%s/%s.go",
			context.Config.Target,
			strings.ToLower(def.Title),
			sectionName,
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
