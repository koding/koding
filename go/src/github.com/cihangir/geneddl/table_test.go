package geneddl

import (
	"encoding/json"

	"testing"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/gene/testdata"
	"github.com/cihangir/schema"
	"github.com/cihangir/stringext"
)

func TestTable(t *testing.T) {
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

		sts, err := DefineTable(context, settingsDef, def)
		if err != nil {
			t.Fatal(err.Error())
		}

		equals(t, expectedTables[index], string(sts))
		index++
	}
}

var expectedTables = []string{
	`-- ----------------------------
--  Table structure for account.profile
-- ----------------------------
DROP TABLE IF EXISTS "account"."profile";
CREATE TABLE "account"."profile" (
    "id" BIGINT DEFAULT nextval('account.profile_id_seq' :: regclass)
        CONSTRAINT "check_profile_id_gte_0" CHECK ("id" >= 0.000000),
    "boolean_bare" BOOLEAN,
    "boolean_with_max_length" BOOLEAN,
    "boolean_with_min_length" BOOLEAN,
    "boolean_with_default" BOOLEAN DEFAULT TRUE,
    "string_bare" TEXT COLLATE "default",
    "string_with_default" TEXT COLLATE "default" DEFAULT 'THISISMYDEFAULTVALUE',
    "string_with_max_length" VARCHAR (24) COLLATE "default",
    "string_with_min_length" TEXT COLLATE "default"
        CONSTRAINT "check_profile_string_with_min_length_min_length_24" CHECK (char_length("string_with_min_length") > 24 ),
    "string_with_max_and_min_length" VARCHAR (24) COLLATE "default"
        CONSTRAINT "check_profile_string_with_max_and_min_length_min_length_4" CHECK (char_length("string_with_max_and_min_length") > 4 ),
    "string_with_pattern" TEXT COLLATE "default"
        CONSTRAINT "check_profile_string_with_pattern_pattern" CHECK ("string_with_pattern" ~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'),
    "string_date_formatted" TIMESTAMP (6) WITH TIME ZONE,
    "string_date_formatted_with_default" TIMESTAMP (6) WITH TIME ZONE DEFAULT now(),
    "string_uuid_formatted" UUID,
    "string_uuid_formatted_with_default" UUID DEFAULT uuid_generate_v1(),
    "number_bare" NUMERIC,
    "number_with_multiple_of" NUMERIC
        CONSTRAINT "check_profile_number_with_multiple_of_multiple_of_2" CHECK (("number_with_multiple_of" % 2.000000) = 0),
    "number_with_multiple_of_formatted_as_float64" NUMERIC
        CONSTRAINT "check_profile_number_with_multiple_of_formatted_as_float64_multiple_of_6" CHECK (("number_with_multiple_of_formatted_as_float64" % 6.400000) = 0),
    "number_with_multiple_of_formatted_as_float32" NUMERIC
        CONSTRAINT "check_profile_number_with_multiple_of_formatted_as_float32_multiple_of_3" CHECK (("number_with_multiple_of_formatted_as_float32" % 3.200000) = 0),
    "number_with_multiple_of_formatted_as_int64" BIGINT
        CONSTRAINT "check_profile_number_with_multiple_of_formatted_as_int64_multiple_of_64" CHECK (("number_with_multiple_of_formatted_as_int64" % 64.000000) = 0),
    "number_with_multiple_of_formatted_as_u_int64" BIGINT
        CONSTRAINT "check_profile_number_with_multiple_of_formatted_as_u_int64_multiple_of_64" CHECK (("number_with_multiple_of_formatted_as_u_int64" % 64.000000) = 0),
    "number_with_multiple_of_formatted_as_int32" INTEGER
        CONSTRAINT "check_profile_number_with_multiple_of_formatted_as_int32_multiple_of_2" CHECK (("number_with_multiple_of_formatted_as_int32" % 2.000000) = 0),
    "enum_bare" "account"."profile_enum_bare_enum",
    "number_with_exclusive_maximum_without_maximum" NUMERIC,
    "number_with_exclusive_minimum" NUMERIC
        CONSTRAINT "check_profile_number_with_exclusive_minimum_gte_0" CHECK ("number_with_exclusive_minimum" >= 0.000000),
    "number_with_exclusive_minimum_without_minimum" NUMERIC,
    "number_with_maximum" NUMERIC
        CONSTRAINT "check_profile_number_with_maximum_lte_1023" CHECK ("number_with_maximum" <= 1023.000000),
    "number_with_maximum_as_float32" NUMERIC
        CONSTRAINT "check_profile_number_with_maximum_as_float32_lte_3" CHECK ("number_with_maximum_as_float32" <= 3.200000),
    "number_with_maximum_as_float64" NUMERIC
        CONSTRAINT "check_profile_number_with_maximum_as_float64_lte_6" CHECK ("number_with_maximum_as_float64" <= 6.400000),
    "number_with_maximum_as_int" INTEGER
        CONSTRAINT "check_profile_number_with_maximum_as_int_lte_2" CHECK ("number_with_maximum_as_int" <= 2.000000),
    "number_with_maximum_as_int16" SMALLINT
        CONSTRAINT "check_profile_number_with_maximum_as_int16_lte_2" CHECK ("number_with_maximum_as_int16" <= 2.000000),
    "number_with_maximum_as_int32" INTEGER
        CONSTRAINT "check_profile_number_with_maximum_as_int32_lte_2" CHECK ("number_with_maximum_as_int32" <= 2.000000),
    "number_with_maximum_as_int64" BIGINT
        CONSTRAINT "check_profile_number_with_maximum_as_int64_lte_64" CHECK ("number_with_maximum_as_int64" <= 64.000000),
    "number_with_maximum_as_int8" SMALLINT
        CONSTRAINT "check_profile_number_with_maximum_as_int8_lte_2" CHECK ("number_with_maximum_as_int8" <= 2.000000),
    "number_with_maximum_as_u_int" INTEGER
        CONSTRAINT "check_profile_number_with_maximum_as_u_int_lte_2" CHECK ("number_with_maximum_as_u_int" <= 2.000000),
    "number_with_maximum_as_u_int16" SMALLINT
        CONSTRAINT "check_profile_number_with_maximum_as_u_int16_lte_2" CHECK ("number_with_maximum_as_u_int16" <= 2.000000),
    "number_with_maximum_as_u_int32" INTEGER
        CONSTRAINT "check_profile_number_with_maximum_as_u_int32_lte_2" CHECK ("number_with_maximum_as_u_int32" <= 2.000000),
    "number_with_maximum_as_u_int64" BIGINT
        CONSTRAINT "check_profile_number_with_maximum_as_u_int64_lte_64" CHECK ("number_with_maximum_as_u_int64" <= 64.000000),
    "number_with_maximum_as_u_int8" SMALLINT
        CONSTRAINT "check_profile_number_with_maximum_as_u_int8_lte_2" CHECK ("number_with_maximum_as_u_int8" <= 2.000000),
    "number_with_minimum_as_float32" NUMERIC
        CONSTRAINT "check_profile_number_with_minimum_as_float32_gte_0" CHECK ("number_with_minimum_as_float32" >= 0.000000),
    "number_with_minimum_as_float64" NUMERIC
        CONSTRAINT "check_profile_number_with_minimum_as_float64_gte_0" CHECK ("number_with_minimum_as_float64" >= 0.000000),
    "number_with_minimum_as_int" INTEGER
        CONSTRAINT "check_profile_number_with_minimum_as_int_gte_0" CHECK ("number_with_minimum_as_int" >= 0.000000),
    "number_with_minimum_as_int16" SMALLINT
        CONSTRAINT "check_profile_number_with_minimum_as_int16_gte_0" CHECK ("number_with_minimum_as_int16" >= 0.000000),
    "number_with_minimum_as_int32" INTEGER
        CONSTRAINT "check_profile_number_with_minimum_as_int32_gte_0" CHECK ("number_with_minimum_as_int32" >= 0.000000),
    "number_with_minimum_as_int64" BIGINT
        CONSTRAINT "check_profile_number_with_minimum_as_int64_gte_0" CHECK ("number_with_minimum_as_int64" >= 0.000000),
    "number_with_minimum_as_int8" SMALLINT
        CONSTRAINT "check_profile_number_with_minimum_as_int8_gte_0" CHECK ("number_with_minimum_as_int8" >= 0.000000),
    "number_with_minimum_as_u_int" INTEGER
        CONSTRAINT "check_profile_number_with_minimum_as_u_int_gte_0" CHECK ("number_with_minimum_as_u_int" >= 0.000000),
    "number_with_minimum_as_u_int16" SMALLINT
        CONSTRAINT "check_profile_number_with_minimum_as_u_int16_gte_0" CHECK ("number_with_minimum_as_u_int16" >= 0.000000),
    "number_with_minimum_as_u_int32" INTEGER
        CONSTRAINT "check_profile_number_with_minimum_as_u_int32_gte_0" CHECK ("number_with_minimum_as_u_int32" >= 0.000000),
    "number_with_minimum_as_u_int64" BIGINT
        CONSTRAINT "check_profile_number_with_minimum_as_u_int64_gte_0" CHECK ("number_with_minimum_as_u_int64" >= 0.000000),
    "number_with_minimum_as_u_int8" SMALLINT
        CONSTRAINT "check_profile_number_with_minimum_as_u_int8_gte_0" CHECK ("number_with_minimum_as_u_int8" >= 0.000000),
    "number_with_multiple_of_formatted_as_int" INTEGER
        CONSTRAINT "check_profile_number_with_multiple_of_formatted_as_int_multiple_of_2" CHECK (("number_with_multiple_of_formatted_as_int" % 2.000000) = 0),
    "number_with_multiple_of_formatted_as_int16" SMALLINT
        CONSTRAINT "check_profile_number_with_multiple_of_formatted_as_int16_multiple_of_2" CHECK (("number_with_multiple_of_formatted_as_int16" % 2.000000) = 0),
    "number_with_multiple_of_formatted_as_int8" SMALLINT
        CONSTRAINT "check_profile_number_with_multiple_of_formatted_as_int8_multiple_of_2" CHECK (("number_with_multiple_of_formatted_as_int8" % 2.000000) = 0),
    "number_with_multiple_of_formatted_as_u_int" INTEGER
        CONSTRAINT "check_profile_number_with_multiple_of_formatted_as_u_int_multiple_of_2" CHECK (("number_with_multiple_of_formatted_as_u_int" % 2.000000) = 0),
    "number_with_multiple_of_formatted_as_u_int16" SMALLINT
        CONSTRAINT "check_profile_number_with_multiple_of_formatted_as_u_int16_multiple_of_2" CHECK (("number_with_multiple_of_formatted_as_u_int16" % 2.000000) = 0),
    "number_with_multiple_of_formatted_as_u_int32" INTEGER
        CONSTRAINT "check_profile_number_with_multiple_of_formatted_as_u_int32_multiple_of_2" CHECK (("number_with_multiple_of_formatted_as_u_int32" % 2.000000) = 0),
    "number_with_multiple_of_formatted_as_u_int8" SMALLINT
        CONSTRAINT "check_profile_number_with_multiple_of_formatted_as_u_int8_multiple_of_2" CHECK (("number_with_multiple_of_formatted_as_u_int8" % 2.000000) = 0)
) WITH (OIDS = FALSE);-- end schema creation
GRANT SELECT, UPDATE ON "account"."profile" TO "social";`,
}
