package statements

import (
	"bytes"
	"text/template"

	"go/format"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

// GenerateTableName generates a simple table name getter function
func GenerateTableName(context *common.Context, settings schema.Generator, s *schema.Schema) ([]byte, error) {
	temp := template.New("table_name_statement.tmpl").Funcs(context.TemplateFuncs)

	if _, err := temp.Parse(TableNameTemplate); err != nil {
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

	if err := temp.ExecuteTemplate(&buf, "table_name_statement.tmpl", data); err != nil {
		return nil, err
	}

	return format.Source(buf.Bytes())
}

// TableNameTemplate holds the template for the TableName function
var TableNameTemplate = `
{{$title := Pointerize .Schema.Title}}
// TableName returns the table name for {{DepunctWithInitialUpper .Schema.Title}}
func ({{$title}} *{{DepunctWithInitialUpper .Schema.Title}}) TableName() string {
    return "{{.Settings.schemaName}}.{{.Settings.tableName}}"
}
`
