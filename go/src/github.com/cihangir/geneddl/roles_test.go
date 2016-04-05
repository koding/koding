package geneddl

import (
	"encoding/json"
	"strings"

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
	moduleName := strings.ToLower(s.Title)
	settings := GenerateSettings(GeneratorName, moduleName, s)

	index := 0
	for _, def := range s.Definitions {

		// schema should have our generator
		if !def.Generators.Has(GeneratorName) {
			continue
		}

		settingsDef := SetDefaultSettings(GeneratorName, settings, def)
		settingsDef.Set("tableName", stringext.ToFieldName(def.Title))

		sts, err := DefineRole(settingsDef, def)
		if err != nil {
			t.Fatal(err.Error())
		}

		common.TestEquals(t, expectedRoles[index], string(sts))
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
