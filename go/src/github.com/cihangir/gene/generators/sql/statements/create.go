package statements

import (
	"bytes"
	"text/template"

	"go/format"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

// GenerateCreate generates the create sql statement for the given schema
func GenerateCreate(context *common.Context, settings schema.Generator, s *schema.Schema) ([]byte, error) {
	temp := template.New("create_statement.tmpl").Funcs(common.TemplateFuncs)

	if _, err := temp.Parse(CreateStatementTemplate); err != nil {
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

	if err := temp.ExecuteTemplate(&buf, "create_statement.tmpl", data); err != nil {
		return nil, err
	}

	return format.Source(buf.Bytes())
}

// CreateStatementTemplate holds the template for the create sql statement generator
var CreateStatementTemplate = `
{{$title := Pointerize .Schema.Title}}
// GenerateCreateSQL generates plain sql for the given {{DepunctWithInitialUpper .Schema.Title}}
func ({{$title}} *{{DepunctWithInitialUpper .Schema.Title}}) GenerateCreateSQL() (string, []interface{}, error) {
    psql := squirrel.StatementBuilder.PlaceholderFormat(squirrel.Dollar).Insert({{$title}}.TableName())
    columns := make([]string, 0)
    values := make([]interface{}, 0)

    {{range $key, $value := SortedSchema .Schema.Properties}}
        {{/* handle strings */}}
        {{if Equal "string" $value.Type}}
            {{/* strings can have special formatting */}}
            {{if Equal "date-time" $value.Format}}
            if !{{$title}}.{{DepunctWithInitialUpper $value.Title}}.IsZero(){
                columns = append(columns, "{{ToFieldName $value.Title}}")
                values = append(values, {{$title}}.{{DepunctWithInitialUpper $value.Title}})
            }
            {{else}}
            if {{$title}}.{{DepunctWithInitialUpper $value.Title}} != "" {
                columns = append(columns, "{{ToFieldName $value.Title}}")
                values = append(values, {{$title}}.{{DepunctWithInitialUpper $value.Title}})
            }
            {{end}}

        {{else if Equal "boolean" $value.Type}}
            if {{$title}}.{{DepunctWithInitialUpper $value.Title}} != false {
                columns = append(columns, "{{ToFieldName $value.Title}}")
                values = append(values, {{$title}}.{{DepunctWithInitialUpper $value.Title}})
            }
        {{else if Equal "number" $value.Type}}
            if float64({{$title}}.{{DepunctWithInitialUpper $value.Title}}) != float64(0) {
                columns = append(columns, "{{ToFieldName $value.Title}}")
                values = append(values, {{$title}}.{{DepunctWithInitialUpper $value.Title}})
            }
        {{end}}
    {{end}}
    return psql.Columns(columns...).Values(values...).ToSql()
}
`
