package geneddl

import (
	"encoding/json"

	"testing"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/gene/testdata"
	"github.com/cihangir/schema"
	"github.com/cihangir/stringext"
)

func TestDatabase(t *testing.T) {
	s := &schema.Schema{}
	err := json.Unmarshal([]byte(testdata.TestDataFull), s)
	common.TestEquals(t, nil, err)

	s = s.Resolve(s)
	g := New()

	context := common.NewContext()
	moduleName := context.ModuleNameFunc(s.Title)
	settings := GenerateSettings(g.Name(), moduleName, s)

	index := 0
	for _, def := range s.Definitions {

		// schema should have our generator
		if !def.Generators.Has(GeneratorName) {
			continue
		}

		settingsDef := SetDefaultSettings(g.Name(), settings, def)
		settingsDef.Set("tableName", stringext.ToFieldName(def.Title))

		sts, err := DefineDatabase(context, settingsDef, def)
		if err != nil {
			t.Fatal(err.Error())
		}

		equals(t, expectedDatabases[index], string(sts))
		index++
	}
}

var expectedDatabases = []string{
	`--
-- Clear previously created database
--
DROP DATABASE IF EXISTS "mydatabase";
--
-- Create database itself
--
CREATE DATABASE "mydatabase" OWNER "social" ENCODING 'UTF8'  TEMPLATE template0;`,
}
