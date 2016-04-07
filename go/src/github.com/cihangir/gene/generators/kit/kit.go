package kit

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"text/template"

	"go/format"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

//
// metric - implement dogstatsd
// throttling - implement one with shared backend
// logging - leveled - filtered
//

// Generator generates kit workers
type Generator struct{}

// Generate generates and writes the errors of the schema
func (g *Generator) Generate(req *common.Req, res *common.Res) error {
	context := req.Context

	if context == nil || context.Config == nil {
		return nil
	}

	if !common.IsIn("kit", context.Config.Generators...) {
		return nil
	}

	if req.Schema == nil {
		if req.SchemaStr == "" {
			return errors.New("both schema and string schema is not set")
		}

		s := &schema.Schema{}
		if err := json.Unmarshal([]byte(req.SchemaStr), s); err != nil {
			return err
		}

		req.Schema = s.Resolve(nil)
	}

	settings, ok := req.Schema.Generators.Get("workers")
	if !ok {
		settings = schema.Generator{}
	}

	settings.SetNX("rootPathPrefix", "workers")
	rootPathPrefix := settings.Get("rootPathPrefix").(string)
	fullPathPrefix := req.Context.Config.Target + rootPathPrefix + "/"
	settings.Set("fullPathPrefix", fullPathPrefix)

	// TODO(cihangir) remove this statement when Process transition is complete
	req.Context.Config.Target = fullPathPrefix
	outputs, err := GenerateKitWorker(context, req.Schema)
	if err != nil {
		return err
	}

	output, err := GenerateInterface(context, req.Schema)
	if err != nil {
		return err
	}

	outputs = append(outputs, output...)

	output, err = GenerateTransportHTTPSemiotics(context, req.Schema)
	if err != nil {
		return err
	}
	outputs = append(outputs, output...)

	output, err = GenerateTransportHTTPServer(context, req.Schema)
	if err != nil {
		return err
	}

	outputs = append(outputs, output...)

	output, err = GenerateTransportHTTPClient(context, req.Schema)
	if err != nil {
		return err
	}

	outputs = append(outputs, output...)

	output, err = GenerateService(context, req.Schema)
	if err != nil {
		return err
	}
	outputs = append(outputs, output...)

	res.Output = outputs
	return nil
}

func generate(context *common.Context, s *schema.Schema, templ string, sectionName string) ([]common.Output, error) {
	temp := template.New("kit.tmpl").Funcs(common.TemplateFuncs)
	if _, err := temp.Parse(templ); err != nil {
		return nil, err
	}

	moduleName := strings.ToLower(s.Title)

	var outputs []common.Output

	for _, def := range common.SortedObjectSchemas(s.Definitions) {
		if len(def.Functions) == 0 {
			continue
		}

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
