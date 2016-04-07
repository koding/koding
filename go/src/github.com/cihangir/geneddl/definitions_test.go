package geneddl

import (
	"testing"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/gene/testdata"
)

func TestDefinitions(t *testing.T) {
	common.RunTest(t, &Generator{}, testdata.TestDataFull, expecteds)
}

var expecteds = []string{`--
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
	`--
-- Clear previously created database
--
DROP DATABASE IF EXISTS "mydatabase";
--
-- Create database itself
--
CREATE DATABASE "mydatabase" OWNER "social" ENCODING 'UTF8'  TEMPLATE template0;`,
	`
-- ----------------------------
--  Required extensions
-- ----------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";`,
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
	`-- ----------------------------
--  Sequence structure for account.profile_id
-- ----------------------------
DROP SEQUENCE IF EXISTS "account"."profile_id_seq" CASCADE;
CREATE SEQUENCE "account"."profile_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
GRANT USAGE ON SEQUENCE "account"."profile_id_seq" TO "social";`,
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
	`-------------------------------
--  Primary key structure for table profile
-- ----------------------------
ALTER TABLE "account"."profile" ADD PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;
-------------------------------
--  Unique key structure for table profile
-- ----------------------------
ALTER TABLE "account"."profile" ADD CONSTRAINT "key_profile_id" UNIQUE ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE "account"."profile" ADD CONSTRAINT "key_profile_boolean_bare_string_bare" UNIQUE ("boolean_bare", "string_bare") NOT DEFERRABLE INITIALLY IMMEDIATE;
-------------------------------
--  Foreign keys structure for table profile
-- ----------------------------
ALTER TABLE "account"."profile" ADD CONSTRAINT "fkey_profile_account_id" FOREIGN KEY ("account_id") REFERENCES account.account (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;`,
}
