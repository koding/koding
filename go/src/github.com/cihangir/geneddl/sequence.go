package geneddl

import (
	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

// DefineSequence creates definition for sequences
func DefineSequence(settings schema.Generator, s *schema.Schema) ([]byte, error) {
	return common.ProcessSingle(&common.Op{
		Template:       SequenceTemplate,
		PostProcessors: []common.PostProcessor{clean},
	}, s, settings)
}

// SequenceTemplate holds the template for sequences
var SequenceTemplate = `-- ----------------------------
--  Sequence structure for {{.Settings.schemaName}}.{{.Settings.tableName}}_id
-- ----------------------------
DROP SEQUENCE IF EXISTS "{{.Settings.schemaName}}"."{{.Settings.tableName}}_id_seq" CASCADE;
CREATE SEQUENCE "{{.Settings.schemaName}}"."{{.Settings.tableName}}_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
GRANT USAGE ON SEQUENCE "{{.Settings.schemaName}}"."{{.Settings.tableName}}_id_seq" TO "{{.Settings.roleName}}";
`
