-- drop table
DROP TABLE IF EXISTS "api"."permission" CASCADE;

DROP SEQUENCE IF EXISTS "api"."permission_id_seq";

-- drop table specific type
DROP TYPE IF EXISTS "api"."permission_status_constant_enum";

-- drop alteration for channel_participant
ALTER TABLE "api"."channel_participant" DROP COLUMN IF EXISTS "role_constant" RESTRICT;

-- drop dependent types
DROP TYPE IF EXISTS "api"."role_constant_enum"
