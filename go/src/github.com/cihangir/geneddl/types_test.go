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

func TestTypes(t *testing.T) {
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

		sts, err := DefineTypes(settingsDef, def)
		if err != nil {
			t.Fatal(err.Error())
		}

		common.TestEquals(t, expectedTypes[index], string(sts))
		index++
	}
}

var expectedTypes = []string{
	`
-- ----------------------------
--  Types structure for account.profile.enum_bare
-- ----------------------------
DROP TYPE IF EXISTS "account"."profile_enum_bare_enum" CASCADE;
CREATE TYPE "account"."profile_enum_bare_enum" AS ENUM (
  'enum1',
  'enum2',
  'enum3'
);
ALTER TYPE "account"."profile_enum_bare_enum" OWNER TO "social";`,
}
