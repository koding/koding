package geneddl

import (
	"bytes"
	"text/template"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

// DefineDatabase creates definition for types
func DefineDatabase(context *common.Context, settings schema.Generator, s *schema.Schema) ([]byte, error) {
	temp := template.New("create_database.tmpl").Funcs(context.TemplateFuncs)
	if _, err := temp.Parse(DatabaseTemplate); err != nil {
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

	if err := temp.ExecuteTemplate(&buf, "create_database.tmpl", data); err != nil {
		return nil, err
	}

	return clean(buf.Bytes()), nil
}

//  DatabaseTemplate holds the template for types
var DatabaseTemplate = `--
-- Clear previously created database
--
DROP DATABASE IF EXISTS "{{.Settings.databaseName}}";

--
-- Create database itself
--
CREATE DATABASE "{{.Settings.databaseName}}" OWNER "{{.Settings.roleName}}" ENCODING 'UTF8'  TEMPLATE template0;
`
