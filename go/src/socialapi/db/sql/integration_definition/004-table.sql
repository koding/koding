
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
    "title" VARCHAR (200) NOT NULL COLLATE "default",
    "icon_path" VARCHAR (200) NOT NULL COLLATE "default",
    "description" TEXT COLLATE "default",
    "instructions" TEXT COLLATE "default",
    "type_constant" "integration"."integration_type_constant_enum",
    "version" VARCHAR(6) NOT NULL COLLATE "default",
    "created_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "updated_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "deleted_at" timestamp(6) WITH TIME ZONE NOT NULL
) WITH (OIDS = FALSE);
GRANT SELECT, INSERT, UPDATE ON "integration"."integration" TO "social";

-- ----------------------------
--  Table structure for team_integration
-- ----------------------------
DROP TABLE IF EXISTS "integration"."team_integration"
CREATE TABLE "integration"."team_integration" (
  "id" BIGINT NOT NULL DEFAULT nextval('integration.team_integration_id_seq'::regclass),
  "bot_name" VARCHAR (200) NOT NULL COLLATE "default",
  "bot_icon_path" VARCHAR (200) NOT NULL COLLATE "default",
  "description" VARCHAR (140) NOT NULL COLLATE "default",
  "token" VARCHAR(20) NOT NULL,
  "integration_id" BIGINT NOT NULL,
  "channel_id" BIGINT NOT NULL,
  "creator_id" BIGINT NOT NULL,
  "is_enabled" BOOLEAN NOT NULL DEFAULT TRUE,
  "created_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now(),
  "updated_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now(),
  "deleted_at" timestamp(6) WITH TIME ZONE NOT NULL
) WITH (OIDS = FALSE);
GRANT SELECT, INSERT, UPDATE ON "integration"."team_integration" TO "social";
