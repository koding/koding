package js

import (
	"bytes"
	"fmt"
	"strings"
	"text/template"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

type Generator struct{}

var PathForStatements = "%smodels/%s_statements.go"

// Generate generates and writes the errors of the schema
func (g *Generator) Generate(context *common.Context, s *schema.Schema) ([]common.Output, error) {
	moduleName := context.ModuleNameFunc(s.Title)
	outputs := make([]common.Output, 0)

	for _, def := range common.SortedObjectSchemas(s.Definitions) {
		output, err := GenerateAPI(context.Config.Target, moduleName, def)
		if err != nil {
			return nil, err
		}

		outputs = append(outputs, output)
	}

	return outputs, nil
}

// GenerateAPI generates and writes the js files
func GenerateAPI(rootPath string, moduleName string, s *schema.Schema) (common.Output, error) {
	api, err := generate(moduleName, s)
	if err != nil {
		return common.Output{}, err
	}

	path := fmt.Sprintf(
		"%s/%s/%s.js",
		rootPath,
		moduleName,
		strings.ToLower(s.Title),
	)

	return common.Output{
		Content:     api,
		Path:        path,
		DoNotFormat: true,
	}, nil

}

// FunctionsTemplate provides the template for js clients of models
var FunctionsTemplate = `module.exports.{{.ModuleName}} = {
    {{$schema := .Schema}} {{$title := $schema.Title}}
    // New creates a new local {{ToUpperFirst $title}} js client
    {{ToUpperFirst $title}} = function(){}

    // create validators
    {{ToUpperFirst $title}}.validate = function(data){
        return  null
    }

    // create mapper
    {{ToUpperFirst $title}}.map = function(data){
        return null
    }

    {{range $funcKey, $funcValue := $schema.Functions}}
    {{ToUpperFirst $title}}.{{$funcKey}} = function(data, callback) {

        // data should be type of {{Argumentize $funcValue.Properties.incoming}}
        {{if Equal "array" $funcValue.Properties.incoming.Type}}
        {{$incoming := index $funcValue.Properties.incoming.Items 0}}
        for (var i = 0; i < data.length; i++){
            if(err = {{$incoming.Title}}.validate(data[i])) {
                return callback(err, null)
            }
        }
        {{else}}
        if(err = {{ToUpperFirst $funcValue.Properties.incoming.Title}}.validate(data)) {
            return callback(err, null)
        }
        {{end}}
        // send request to the server

        // we got the response
        var res = {}

        // response should be type of {{Argumentize $funcValue.Properties.outgoing}}
        {{if Equal "array" $funcValue.Properties.outgoing.Type}}
        {{$outgoing := index $funcValue.Properties.outgoing.Items 0}}
        res = res.map(function(datum) {
          return {{ToUpperFirst $outgoing.Title}}.map(datum);
        });
        {{else}}
        res = {{ToUpperFirst $funcValue.Properties.outgoing.Title}}.map(res)
        {{end}}

        callback(null, res)
    }
    {{end}}
}
`

// Generate generates the js clients for given schema/model
func generate(moduleName string, s *schema.Schema) ([]byte, error) {
	temp := template.New("js clients.tmpl").Funcs(common.TemplateFuncs)

	if _, err := temp.Parse(FunctionsTemplate); err != nil {
		return nil, err
	}

	var buf bytes.Buffer

	data := struct {
		ModuleName string
		Schema     *schema.Schema
	}{
		ModuleName: moduleName,
		Schema:     s,
	}

	if err := temp.ExecuteTemplate(&buf, "js clients.tmpl", data); err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}
