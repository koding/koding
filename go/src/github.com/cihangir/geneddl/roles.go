package geneddl

import (
	"bytes"
	"text/template"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

// DefineRole creates definition for types
func DefineRole(context *common.Context, settings schema.Generator, s *schema.Schema) ([]byte, error) {
	temp := template.New("create_role.tmpl").Funcs(context.TemplateFuncs)
	if _, err := temp.Parse(RoleTemplate); err != nil {
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

	if err := temp.ExecuteTemplate(&buf, "create_role.tmpl", data); err != nil {
		return nil, err
	}

	return clean(buf.Bytes()), nil
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
