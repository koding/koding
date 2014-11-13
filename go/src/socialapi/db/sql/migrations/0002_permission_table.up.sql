
-- ----------------------------
--  Sequence structure for permission_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "api"."permission_id_seq";
CREATE SEQUENCE "api"."permission_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
GRANT USAGE ON SEQUENCE "api"."permission_id_seq" TO "social";


CREATE TYPE "api"."role_constant_enum" AS ENUM (
    'admin',
    'moderator',
    'member',
    'guest'
);

CREATE TYPE "api"."permission_status_constant_enum" AS ENUM (
    'allowed',
    'disallowed'
);

DROP TABLE IF EXISTS "api"."permission";
CREATE TABLE "api"."permission" (
    "id" BIGINT NOT NULL DEFAULT nextval(
        'api.permission_id_seq' :: regclass
    ),
    "name" VARCHAR(200) NOT NULL COLLATE "default",
    "channel_id" BIGINT NOT NULL,
    "role_constant" "api"."role_constant_enum",
    "status_constant" "api"."permission_status_constant_enum",
    "created_at" TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    "updated_at" TIMESTAMP(6) WITH TIME ZONE NOT NULL
) WITH (OIDS=FALSE);
GRANT SELECT, INSERT, UPDATE ON "api"."permission" TO "social";
ALTER TABLE "api"."permission" ADD PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE "api"."permission" ADD CONSTRAINT "permission_name_channel_id_role_constant_key" UNIQUE ("name","channel_id","role_constant") NOT DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE "api"."permission" ADD CONSTRAINT "permission_channel_id_fkey" FOREIGN KEY ("channel_id") REFERENCES "api"."channel" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;


-------------
-- channel participant table
-------------
ALTER TABLE "api"."channel_participant" DROP COLUMN IF EXISTS "role_constant" RESTRICT;
ALTER TABLE "api"."channel_participant" ADD COLUMN "role_constant" "api"."role_constant_enum" DEFAULT 'member';
