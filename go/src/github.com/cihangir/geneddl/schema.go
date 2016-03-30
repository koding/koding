package geneddl

import (
	"bytes"
	"text/template"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

// DefineSchema creates definition for schema
func DefineSchema(context *common.Context, settings schema.Generator, s *schema.Schema) ([]byte, error) {
	temp := template.New("create_schema.tmpl").Funcs(common.TemplateFuncs)
	if _, err := temp.Parse(SchemaTemplate); err != nil {
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
	if err := temp.ExecuteTemplate(&buf, "create_schema.tmpl", data); err != nil {
		return nil, err
	}

	return clean(buf.Bytes()), nil
}

//  SchemaTemplate holds the template for sequences
var SchemaTemplate = `-- ----------------------------
--  Schema structure for {{.Settings.schemaName}}
-- ----------------------------
CREATE SCHEMA IF NOT EXISTS "{{.Settings.schemaName}}";
--
-- Give usage permission
--
GRANT usage ON SCHEMA "{{.Settings.schemaName}}" to "{{.Settings.roleName}}";
--
-- add new schema to search path -just for convenience
-- SELECT set_config('search_path', current_setting('search_path') || ',{{.Settings.schemaName}}', false);`
