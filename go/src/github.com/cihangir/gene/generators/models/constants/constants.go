// Package constants generates the constant variables for a model/schema
package constants

import (
	"bytes"
	"text/template"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/gene/utils"
	"github.com/cihangir/schema"
)

// Generate generates the constants for given schema/model
func Generate(s *schema.Schema) ([]byte, error) {
	temp := template.New("constants.tmpl").Funcs(common.TemplateFuncs)
	if _, err := temp.Parse(ConstantsTemplate); err != nil {
		return nil, err
	}

	data := struct {
		Schema *schema.Schema
	}{
		Schema: s,
	}

	var buf bytes.Buffer

	if err := temp.ExecuteTemplate(&buf, "constants.tmpl", data); err != nil {
		return nil, err
	}

	return utils.Clear(buf)
}

// ConstantsTemplate holds the template for the constant generation
var ConstantsTemplate = `
{{$title := .Schema.Title}}
{{range $key, $value := .Schema.Properties}}
    {{if len $value.Enum}}
        // {{DepunctWithInitialUpper $title}}{{DepunctWithInitialUpper $key}} holds the predefined enums
        var {{DepunctWithInitialUpper $title}}{{DepunctWithInitialUpper $key}}  = struct {
        {{range $defKey, $val := $value.Enum}}
            {{DepunctWithInitialUpper $val}} string
        {{end}}
        }{
        {{range $defKey, $val := $value.Enum}}
            {{DepunctWithInitialUpper $val}}: "{{$val}}",
        {{end}}
        }
    {{end}}
{{end}}
`
