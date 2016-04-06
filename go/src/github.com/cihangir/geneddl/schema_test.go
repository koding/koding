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

func TestSchema(t *testing.T) {
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

		sts, err := DefineSchema(settingsDef, def)
		if err != nil {
			t.Fatal(err.Error())
		}

		common.TestEquals(t, expectedSchemas[index], string(sts))
		index++
	}
}

var expectedSchemas = []string{
	`-- ----------------------------
--  Schema structure for account
-- ----------------------------
CREATE SCHEMA IF NOT EXISTS "account";
--
-- Give usage permission
--
GRANT usage ON SCHEMA "account" to "social";
--
-- add new schema to search path -just for convenience
-- SELECT set_config('search_path', current_setting('search_path') || ',account', false);`,
}
