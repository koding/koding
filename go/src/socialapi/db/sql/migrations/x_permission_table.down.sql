-- drop table
DROP TABLE IF EXISTS "api"."permission" CASCADE;

-- drop table's sequence
DROP SEQUENCE IF EXISTS "api"."permission_id_seq";

-----------------------------------------------------------------------

-- drop permission_status_constant_enum type
DROP TYPE IF EXISTS "api"."permission_status_constant_enum";

-- drop role_constant_enum type
DROP TYPE IF EXISTS "api"."role_constant_enum"

-----------------------------------------------------------------------

-- drop role_constant from channel_participant
ALTER TABLE "api"."channel_participant" DROP COLUMN IF EXISTS "role_constant" RESTRICT;
