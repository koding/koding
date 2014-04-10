SET ROLE social;
-- ----------------------------
--  Primary key structure for table channel
-- ----------------------------
ALTER TABLE "api"."channel" ADD PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;

-- ----------------------------
--  Primary key structure for table account
-- ----------------------------
ALTER TABLE "api"."account" ADD PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;

-- ----------------------------
--  Uniques structure for table account
-- ----------------------------
ALTER TABLE "api"."account" ADD CONSTRAINT "account_old_id_key" UNIQUE ("old_id") NOT DEFERRABLE INITIALLY IMMEDIATE;

-- ----------------------------
--  Primary key structure for table channel_message
-- ----------------------------
ALTER TABLE "api"."channel_message" ADD PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;

-- ----------------------------
--  Primary key structure for table channel_message_list
-- ----------------------------
ALTER TABLE "api"."channel_message_list" ADD PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;

-- ----------------------------
--  Primary key structure for table channel_participant
-- ----------------------------
ALTER TABLE "api"."channel_participant" ADD PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;

-- ----------------------------
--  Primary key structure for table interaction
-- ----------------------------
ALTER TABLE "api"."interaction" ADD PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;

-- ----------------------------
--  Primary key structure for table message_reply
-- ----------------------------
ALTER TABLE "api"."message_reply" ADD PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;

-- ----------------------------
--  Primary key structure for table notification
-- ----------------------------
ALTER TABLE "api"."notification" ADD PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;

-- ----------------------------
--  Primary key structure for table notification_content
-- ----------------------------
ALTER TABLE "api"."notification_content" ADD PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;