package geneddl

import (
	"bytes"
	"text/template"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

// DefineSequence creates definition for sequences
func DefineSequence(context *common.Context, settings schema.Generator, s *schema.Schema) ([]byte, error) {
	temp := template.New("create_sequences.tmpl").Funcs(context.TemplateFuncs)
	if _, err := temp.Parse(SequenceTemplate); err != nil {
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

	if err := temp.ExecuteTemplate(&buf, "create_sequences.tmpl", data); err != nil {
		return nil, err
	}

	return clean(buf.Bytes()), nil
}

// SequenceTemplate holds the template for sequences
var SequenceTemplate = `-- ----------------------------
--  Sequence structure for {{.Settings.schemaName}}.{{.Settings.tableName}}_id
-- ----------------------------
DROP SEQUENCE IF EXISTS "{{.Settings.schemaName}}"."{{.Settings.tableName}}_id_seq" CASCADE;
CREATE SEQUENCE "{{.Settings.schemaName}}"."{{.Settings.tableName}}_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
GRANT USAGE ON SEQUENCE "{{.Settings.schemaName}}"."{{.Settings.tableName}}_id_seq" TO "{{.Settings.roleName}}";
`
