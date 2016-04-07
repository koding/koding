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

func TestSequence(t *testing.T) {
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

		sts, err := DefineSequence(settingsDef, def)
		if err != nil {
			t.Fatal(err.Error())
		}

		common.TestEquals(t, expectedSequences[index], string(sts))
		index++
	}
}

var expectedSequences = []string{
	`-- ----------------------------
--  Sequence structure for account.profile_id
-- ----------------------------
DROP SEQUENCE IF EXISTS "account"."profile_id_seq" CASCADE;
CREATE SEQUENCE "account"."profile_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
GRANT USAGE ON SEQUENCE "account"."profile_id_seq" TO "social";`,
}
