-- ----------------------------
--  Table structure for tinder_schema.profile
-- ----------------------------
DROP TABLE IF EXISTS "tinder_schema"."profile";
CREATE TABLE "tinder_schema"."profile" (
    "id" BIGINT DEFAULT nextval('tinder_schema.profile_id_seq' :: regclass)
        CONSTRAINT "check_profile_id_gte_0" CHECK ("id" >= 0.000000),
    "screen_name" VARCHAR (20) COLLATE "default"
        CONSTRAINT "check_profile_screen_name_min_length_4" CHECK (char_length("screen_name") > 4 ),
    "location" VARCHAR (30) COLLATE "default",
    "description" VARCHAR (160) COLLATE "default",
    "created_at" TIMESTAMP (6) WITH TIME ZONE DEFAULT now(),
    "updated_at" TIMESTAMP (6) WITH TIME ZONE DEFAULT now(),
    "deleted_at" TIMESTAMP (6) WITH TIME ZONE
) WITH (OIDS = FALSE);-- end schema creation
GRANT SELECT, INSERT, UPDATE ON "tinder_schema"."profile" TO "tinder_role";