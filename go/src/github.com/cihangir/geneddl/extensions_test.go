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

func TestExtensions(t *testing.T) {
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

		sts, err := DefineExtensions(settingsDef, def)
		if err != nil {
			t.Fatal(err.Error())
		}

		common.TestEquals(t, expectedExtensions[index], string(sts))
		index++
	}
}

var expectedExtensions = []string{
	`
-- ----------------------------
--  Required extensions
-- ----------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";`, // account.profile
}
