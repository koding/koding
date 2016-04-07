package schema

import (
	"text/template"

	"github.com/cihangir/stringext"
)

// Helpers holds helpers for templates
var Helpers = template.FuncMap{
	"AsComment":               stringext.AsComment,
	"JSONTagWithIgnored":      stringext.JSONTagWithIgnored,
	"goType":                  goType,
	"GenerateValidator":       generateValidator,
	"ToLowerFirst":            stringext.ToLowerFirst,
	"ToUpperFirst":            stringext.ToUpperFirst,
	"DepunctWithInitialUpper": stringext.DepunctWithInitialUpper,
	"DepunctWithInitialLower": stringext.DepunctWithInitialLower,
}

func generateValidator(s *Schema) string {
	return ""
}

var templates *template.Template

func init() {
	templates = template.New("package.tmpl").Funcs(Helpers)
	templates = template.Must(Parse(templates))
}

var tmpls = map[string]string{"field.tmpl": `

{{AsComment .Definition.Description}}
{{DepunctWithInitialUpper .Name}} {{.Type}} {{JSONTagWithIgnored .Name .Required .Definition.Private .Type .Definition.Tags}}
`,
}

// Parse parses declared templates.
func Parse(t *template.Template) (*template.Template, error) {
	for name, s := range tmpls {
		if t == nil {
			t = template.New(name)
		}
		var tmpl *template.Template
		if name == t.Name() {
			tmpl = t
		} else {
			tmpl = t.New(name)
		}
		if _, err := tmpl.Parse(s); err != nil {
			return nil, err
		}
	}
	return t, nil
}
