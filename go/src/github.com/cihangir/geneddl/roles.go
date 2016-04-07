package geneddl

import (
	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

// DefineRole creates definition for types
func DefineRole(settings schema.Generator, s *schema.Schema) ([]byte, error) {
	return common.ProcessSingle(&common.Op{
		Template:       RoleTemplate,
		PostProcessors: []common.PostProcessor{clean},
	}, s, settings)
}

// RoleTemplate holds the template for types
var RoleTemplate = `--
-- Create Parent Role
--
DROP ROLE IF EXISTS "{{.Settings.roleName}}";
CREATE ROLE "{{.Settings.roleName}}";
--
-- Create shadow user for future extensibility
--
DROP USER IF EXISTS "{{.Settings.roleName}}application";
CREATE USER "{{.Settings.roleName}}application" PASSWORD '{{.Settings.roleName}}application';
--
-- Convert our application user to parent
--
GRANT "{{.Settings.roleName}}" TO "{{.Settings.roleName}}application";
`
