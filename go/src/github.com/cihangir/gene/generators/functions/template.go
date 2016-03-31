package functions

// FunctionsTemplate provides the template for constructors of models
var FunctionsTemplate = `
{{$schema := .Schema}}
{{$title := $schema.Title}}

package {{ToLower .ModuleName}}api

// New creates a new local {{ToUpperFirst $title}} handler
func New{{ToUpperFirst $title}}() *{{ToUpperFirst $title}} { return &{{ToUpperFirst $title}}{} }

// {{ToUpperFirst $title}} is for holding the api functions
type {{ToUpperFirst $title}} struct{}

{{range $funcKey, $funcValue := $schema.Functions}}
func ({{Pointerize $title}} *{{$title}}) {{$funcKey}}(ctx context.Context, req *{{Argumentize $funcValue.Properties.incoming}}, res *{{Argumentize $funcValue.Properties.outgoing}}) error {
    return db.MustGetDB(ctx).{{$funcKey}}(models.New{{ToUpperFirst $title}}(), req, res)
}
{{end}}
`
