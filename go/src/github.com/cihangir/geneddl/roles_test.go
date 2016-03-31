package geneddl

import (
	"encoding/json"

	"testing"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/gene/testdata"
	"github.com/cihangir/schema"
	"github.com/cihangir/stringext"
)

func TestRoles(t *testing.T) {
	s := &schema.Schema{}
	if err := json.Unmarshal([]byte(testdata.TestDataFull), s); err != nil {
		t.Fatal(err.Error())
	}

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

		sts, err := DefineRole(context, settingsDef, def)
		if err != nil {
			t.Fatal(err.Error())
		}

		equals(t, expectedRoles[index], string(sts))
		index++
	}
}

var expectedRoles = []string{
	`--
-- Create Parent Role
--
DROP ROLE IF EXISTS "social";
CREATE ROLE "social";
--
-- Create shadow user for future extensibility
--
DROP USER IF EXISTS "socialapplication";
CREATE USER "socialapplication" PASSWORD 'socialapplication';
--
-- Convert our application user to parent
--
GRANT "social" TO "socialapplication";`,
}
