package geneddl

import (
	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

// DefineSchema creates definition for schema
func DefineSchema(settings schema.Generator, s *schema.Schema) ([]byte, error) {
	return common.ProcessSingle(&common.Op{
		Template:       SchemaTemplate,
		PostProcessors: []common.PostProcessor{clean},
	}, s, settings)
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
