-- ----------------------------
--  Table structure for sitemap
-- ----------------------------
DROP TABLE IF EXISTS "sitemap"."file";
CREATE TABLE "sitemap"."file" (
    "id" bigint NOT NULL DEFAULT nextval('sitemap.file_id_seq'::regclass),
    "name" varchar(20) NOT NULL COLLATE "default",
    "blob" bytea,
    "created_at" timestamp(6) WITH TIME ZONE,
    "updated_at" timestamp(6) WITH TIME ZONE
)
WITH (OIDS=FALSE);
-- GRANT SELECT, INSERT, UPDATE ON "sitemap"."file" TO "socialapplication";
-- TODO all permissions are granted for testing purposes
-- we need another test user here
ALTER TABLE "sitemap"."file" OWNER TO "socialapplication";