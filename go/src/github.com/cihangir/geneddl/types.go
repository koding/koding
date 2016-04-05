package geneddl

import (
	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

// DefineTypes creates definition for types
func DefineTypes(settings schema.Generator, s *schema.Schema) ([]byte, error) {
	return common.ProcessSingle(&common.Op{
		Template:       TypeTemplate,
		PostProcessors: []common.PostProcessor{clean},
	}, s, settings)
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
