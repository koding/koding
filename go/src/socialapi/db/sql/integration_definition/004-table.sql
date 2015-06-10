
-- ----------------------------
--  General types
-- ----------------------------
CREATE TYPE "integration"."integration_type_constant_enum" AS ENUM (
  'incoming',
  'outgoing'
);

-- ----------------------------
--  Table structure for integration
-- ----------------------------
DROP TABLE IF EXISTS "integration"."integration";
CREATE TABLE "integration"."integration" (
    "id" BIGINT NOT NULL DEFAULT nextval('integration.integration_id_seq'::regclass),
    "name" VARCHAR (200) NOT NULL CHECK ("name" <> ''),
    "title" VARCHAR (200) NOT NULL COLLATE "default",
    "icon_path" VARCHAR (2000) COLLATE "default",
    "summary" TEXT COLLATE "default",
    "description" TEXT COLLATE "default",
    "instructions" TEXT COLLATE "default",
    "type_constant" "integration"."integration_type_constant_enum",
    "settings" hstore,
    "is_published" BOOLEAN NOT NULL DEFAULT FALSE,
    "created_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "updated_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "deleted_at" timestamp(6) WITH TIME ZONE
) WITH (OIDS = FALSE);
GRANT SELECT, INSERT, UPDATE ON "integration"."integration" TO "social";

-- ----------------------------
--  Table structure for channel_integration
-- ----------------------------
DROP TABLE IF EXISTS "integration"."channel_integration";
CREATE TABLE "integration"."channel_integration" (
  "id" BIGINT NOT NULL DEFAULT nextval('integration.channel_integration_id_seq'::regclass),
  "description" VARCHAR (140) NOT NULL COLLATE "default",
  "token" UUID NOT NULL DEFAULT uuid_generate_v4(),
  "integration_id" BIGINT NOT NULL,
  "group_name" VARCHAR(200) NOT NULL CHECK ("group_name" <> '') COLLATE "default",
  "channel_id" BIGINT NOT NULL,
  "creator_id" BIGINT NOT NULL,
  "is_disabled" BOOLEAN NOT NULL DEFAULT TRUE,
  "settings" hstore,
  "created_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now(),
  "updated_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now(),
  "deleted_at" timestamp(6) WITH TIME ZONE
) WITH (OIDS = FALSE);
GRANT SELECT, INSERT, UPDATE ON "integration"."channel_integration" TO "social";
