-- ----------------------------
--  Table structure for tinder_schema.facebook_friends
-- ----------------------------
DROP TABLE IF EXISTS "tinder_schema"."facebook_friends";
CREATE TABLE "tinder_schema"."facebook_friends" (
    "source_id" TEXT COLLATE "default"
        CONSTRAINT "check_facebook_friends_source_id_min_length_1" CHECK (char_length("source_id") > 1 ),
    "target_id" TEXT COLLATE "default"
        CONSTRAINT "check_facebook_friends_target_id_min_length_1" CHECK (char_length("target_id") > 1 )
) WITH (OIDS = FALSE);-- end schema creation
GRANT SELECT, INSERT, DELETE ON "tinder_schema"."facebook_friends" TO "twitter_db_role";