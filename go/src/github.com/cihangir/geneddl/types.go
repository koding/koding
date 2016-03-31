package geneddl

import (
	"bytes"
	"text/template"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

// DefineTypes creates definition for types
func DefineTypes(context *common.Context, settings schema.Generator, s *schema.Schema) ([]byte, error) {
	temp := template.New("create_types.tmpl").Funcs(context.TemplateFuncs)
	if _, err := temp.Parse(TypeTemplate); err != nil {
		return nil, err
	}

	var buf bytes.Buffer

	data := struct {
		Context  *common.Context
		Schema   *schema.Schema
		Settings schema.Generator
	}{
		Context:  context,
		Schema:   s,
		Settings: settings,
	}

	if err := temp.ExecuteTemplate(&buf, "create_types.tmpl", data); err != nil {
		return nil, err
	}

	return clean(buf.Bytes()), nil
}

// TypeTemplate holds the template for types
var TypeTemplate = `{{$schemaName := .Settings.schemaName}}
{{$tableName := .Settings.tableName}}
{{$roleName := .Settings.roleName}}
{{range $key, $value := .Schema.Properties}}
{{if len $value.Enum}}
-- ----------------------------
--  Types structure for {{$schemaName}}.{{$tableName}}.{{ToFieldName $value.Title}}
-- ----------------------------
DROP TYPE IF EXISTS "{{$schemaName}}"."{{$tableName}}_{{ToFieldName $value.Title}}_{{ToFieldName "enum"}}" CASCADE;
CREATE TYPE "{{$schemaName}}"."{{$tableName}}_{{ToFieldName $value.Title}}_{{ToFieldName "enum"}}" AS ENUM (
  '{{Join $value.Enum "',\n  '"}}'
);
ALTER TYPE "{{$schemaName}}"."{{$tableName}}_{{ToFieldName $value.Title}}_{{ToFieldName "enum"}}" OWNER TO "{{$roleName}}";
{{end}}
{{end}}
`
