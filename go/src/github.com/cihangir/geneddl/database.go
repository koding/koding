package geneddl

import (
	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

// DefineDatabase creates definition for types
func DefineDatabase(settings schema.Generator, s *schema.Schema) ([]byte, error) {
	return common.ProcessSingle(&common.Op{
		Template:       DatabaseTemplate,
		PostProcessors: []common.PostProcessor{clean},
	}, s, settings)
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
