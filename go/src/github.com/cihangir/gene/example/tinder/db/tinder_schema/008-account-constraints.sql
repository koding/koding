-------------------------------
--  Primary key structure for table account
-- ----------------------------
ALTER TABLE "tinder_schema"."account" ADD PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;
-------------------------------
--  Unique key structure for table account
-- ----------------------------
ALTER TABLE "tinder_schema"."account" ADD CONSTRAINT "key_account_id" UNIQUE ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE "tinder_schema"."account" ADD CONSTRAINT "key_account_url" UNIQUE ("url") NOT DEFERRABLE INITIALLY IMMEDIATE;
-------------------------------
--  Foreign keys structure for table account
-- ----------------------------
ALTER TABLE "tinder_schema"."account" ADD CONSTRAINT "fkey_account_profile_id" FOREIGN KEY ("profile_id") REFERENCES account.profile (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;