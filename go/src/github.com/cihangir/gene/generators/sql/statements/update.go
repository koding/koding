package statements

import (
	"bytes"
	"text/template"

	"go/format"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

// GenerateUpdate generates the update sql statement for the given schema
func GenerateUpdate(context *common.Context, settings schema.Generator, s *schema.Schema) ([]byte, error) {
	temp := template.New("update_statement.tmpl").Funcs(common.TemplateFuncs)
	if _, err := temp.Parse(UpdateStatementTemplate); err != nil {
		return nil, err
	}

	data := struct {
		Context  *common.Context
		Schema   *schema.Schema
		Settings schema.Generator
	}{
		Context:  context,
		Schema:   s,
		Settings: settings,
	}

	var buf bytes.Buffer

	if err := temp.ExecuteTemplate(&buf, "update_statement.tmpl", data); err != nil {
		return nil, err
	}

	return format.Source(buf.Bytes())
}

// UpdateStatementTemplate holds the template for the update sql statement generator
var UpdateStatementTemplate = `
{{$title := Pointerize .Schema.Title}}
// GenerateUpdateSQL generates plain update sql statement for the given {{DepunctWithInitialUpper .Schema.Title}}
func ({{$title}} *{{DepunctWithInitialUpper .Schema.Title}}) GenerateUpdateSQL() (string, []interface{}, error) {
    psql := squirrel.StatementBuilder.PlaceholderFormat(squirrel.Dollar).Update({{$title}}.TableName())

    {{range $key, $value := SortedSchema .Schema.Properties}}
        {{$name := DepunctWithInitialUpper $value.Title}}
        {{if Equal "ID" $name}}
        {{/* do not add id into statements */}}
        {{/* handle strings */}}
        {{else if Equal "string" $value.Type}}
            {{/* strings can have special formatting */}}
            {{if Equal "date-time" $value.Format}}
            if !{{$title}}.{{$name}}.IsZero(){
                psql = psql.Set("{{ToFieldName $value.Title}}", {{$title}}.{{$name}})
            }
            {{else}}
            if {{$title}}.{{$name}} != "" {
                psql = psql.Set("{{ToFieldName $value.Title}}", {{$title}}.{{$name}})
            }
            {{end}}

        {{else if Equal "boolean" $value.Type}}
            if {{$title}}.{{$name}} != false {
                psql = psql.Set("{{ToFieldName $value.Title}}", {{$title}}.{{$name}})
            }
        {{else if Equal "number" $value.Type}}
            if float64({{$title}}.{{$name}}) != float64(0) {
                psql = psql.Set("{{ToFieldName $value.Title}}", {{$title}}.{{$name}})
            }
        {{end}}
    {{end}}

    {{/* TODO get this ID section from the primary key*/}}
    return psql.Where("{{ToFieldName "Id"}} = ?", {{$title}}.{{DepunctWithInitialUpper "ID"}}).ToSql()
}
`
