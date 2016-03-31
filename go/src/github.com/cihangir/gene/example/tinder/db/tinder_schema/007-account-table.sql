-- ----------------------------
--  Table structure for tinder_schema.account
-- ----------------------------
DROP TABLE IF EXISTS "tinder_schema"."account";
CREATE TABLE "tinder_schema"."account" (
    "id" BIGINT DEFAULT nextval('tinder_schema.account_id_seq' :: regclass)
        CONSTRAINT "check_account_id_gte_0" CHECK ("id" >= 0.000000),
    "profile_id" BIGINT
        CONSTRAINT "check_account_profile_id_gte_0" CHECK ("profile_id" >= 0.000000),
    "facebook_id" TEXT COLLATE "default"
        CONSTRAINT "check_account_facebook_id_min_length_1" CHECK (char_length("facebook_id") > 1 ),
    "facebook_access_token" TEXT COLLATE "default"
        CONSTRAINT "check_account_facebook_access_token_min_length_1" CHECK (char_length("facebook_access_token") > 1 ),
    "facebook_secret_token" TEXT COLLATE "default"
        CONSTRAINT "check_account_facebook_secret_token_min_length_1" CHECK (char_length("facebook_secret_token") > 1 ),
    "email_address" TEXT COLLATE "default",
    "email_status_constant" "tinder_schema"."account_email_status_constant_enum" DEFAULT 'notVerified',
    "status_constant" "tinder_schema"."account_status_constant_enum" DEFAULT 'registered',
    "created_at" TIMESTAMP (6) WITH TIME ZONE DEFAULT now(),
    "updated_at" TIMESTAMP (6) WITH TIME ZONE DEFAULT now(),
    "deleted_at" TIMESTAMP (6) WITH TIME ZONE
) WITH (OIDS = FALSE);-- end schema creation
GRANT SELECT, INSERT, UPDATE ON "tinder_schema"."account" TO "tinder_role";