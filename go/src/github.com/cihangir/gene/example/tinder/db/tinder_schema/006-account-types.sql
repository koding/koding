
-- ----------------------------
--  Types structure for tinder_schema.account.email_status_constant
-- ----------------------------
DROP TYPE IF EXISTS "tinder_schema"."account_email_status_constant_enum" CASCADE;
CREATE TYPE "tinder_schema"."account_email_status_constant_enum" AS ENUM (
  'verified',
  'notVerified'
);
ALTER TYPE "tinder_schema"."account_email_status_constant_enum" OWNER TO "tinder_role";
-- ----------------------------
--  Types structure for tinder_schema.account.status_constant
-- ----------------------------
DROP TYPE IF EXISTS "tinder_schema"."account_status_constant_enum" CASCADE;
CREATE TYPE "tinder_schema"."account_status_constant_enum" AS ENUM (
  'registered',
  'disabled',
  'spam'
);
ALTER TYPE "tinder_schema"."account_status_constant_enum" OWNER TO "tinder_role";