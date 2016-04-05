// Package constructors generates the constructors for given schema/model
package constructors

import (
	"bytes"
	"text/template"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/gene/utils"
	"github.com/cihangir/schema"
)

// Generate generates the constructors for given schema/model
func Generate(s *schema.Schema) ([]byte, error) {
	temp := template.New("constructors.tmpl").Funcs(common.TemplateFuncs)

	if _, err := temp.Parse(ConstructorsTemplate); err != nil {
		return nil, err
	}

	data := struct {
		Schema *schema.Schema
	}{
		Schema: s,
	}

	var buf bytes.Buffer

	if err := temp.ExecuteTemplate(&buf, "constructors.tmpl", data); err != nil {
		return nil, err
	}

	return utils.Clear(buf)
}

// ConstructorsTemplate provides the template for constructors of models
var ConstructorsTemplate = `
{{$title := DepunctWithInitialUpper .Schema.Title}}
// New{{$title}} creates a new {{$title}} struct with default values
func New{{$title}}() *{{$title}} {
    return &{{DepunctWithInitialUpper .Schema.Title}}{
        {{range $key, $value := .Schema.Properties}}
            {{/* only process if default value is set */}}
            {{if $value.Default}}
                {{/* handle strings */}}
                {{if Equal "string" $value.Type}}
                    {{/* if property is enum, handle them accordingly */}}
                    {{if len $value.Enum}}
                        {{DepunctWithInitialUpper $key}}: {{$title}}{{DepunctWithInitialUpper $key}}.{{DepunctWithInitialUpper $value.Default}},
                    {{else}}
                        {{/* strings can have special formatting */}}
                        {{/* no-matter what value set for a date-time field, set UTC Now */}}
                        {{if Equal "date-time" $value.Format}}
                            {{DepunctWithInitialUpper $key}}: time.Now().UTC(),
                        {{else}}
                            {{DepunctWithInitialUpper $key}}: "{{$value.Default}}",
                        {{end}}
                    {{end}}
                {{else}}
                    {{/* for boolean, numbers.. */}}
                    {{DepunctWithInitialUpper $key}}: {{$value.Default}},
                {{end}}
            {{end}}
        {{end}}
    }
}
`
