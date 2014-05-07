-- Table Structure should be in the following format
-- 1 Primary Keys
-- 2 Unique Keys
-- 3 Foreign Keys
-- 4 Indexes
SET ROLE social;

-- ------------------------------------------------------------------------------------------
--  Structure for table Account
-- ------------------------------------------------------------------------------------------
-- ----------------------------
--  Primary key structure for table account
-- ----------------------------
ALTER TABLE "api"."account" ADD PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Uniques structure for table account
-- ----------------------------
ALTER TABLE "api"."account" ADD CONSTRAINT "account_old_id_key" UNIQUE ("old_id") NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Indexes structure for table account
-- ----------------------------
CREATE UNIQUE INDEX  "account_id_key" ON "api"."account" USING btree("id" ASC NULLS LAST);

-- ------------------------------------------------------------------------------------------
--  Structure for table Channel
-- ------------------------------------------------------------------------------------------
-------------------------------
--  Primary key structure for table channel
-- ----------------------------
ALTER TABLE "api"."channel" ADD PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Foreign keys structure for table channel
-- ----------------------------
ALTER TABLE "api"."channel" ADD CONSTRAINT "channel_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "api"."account" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Indexes structure for table channel
-- ----------------------------
CREATE UNIQUE INDEX  "channel_id_key" ON "api"."channel" USING btree("id" ASC NULLS LAST);

-- ------------------------------------------------------------------------------------------
--  Structure for table ChannelMessage
-- ------------------------------------------------------------------------------------------
-- ----------------------------
--  Primary key structure for table channel_message
-- ----------------------------
ALTER TABLE "api"."channel_message" ADD PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Foreign keys structure for table channel_message
-- ----------------------------
ALTER TABLE "api"."channel_message" ADD CONSTRAINT "channel_message_initial_channel_id_fkey" FOREIGN KEY ("initial_channel_id") REFERENCES "api"."channel" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE "api"."channel_message" ADD CONSTRAINT "channel_message_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "api"."account" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Indexes structure for table channel_message
-- ----------------------------
CREATE UNIQUE INDEX  "channel_message_id_key" ON "api"."channel_message" USING btree("id" ASC NULLS LAST);


-- ----------------------------------------------------------------------------------------
--  Structure for table ChannelMessageList
-- ----------------------------------------------------------------------------------------
-- ----------------------------
--  Primary key structure for table channel_message_list
-- ----------------------------
ALTER TABLE "api"."channel_message_list" ADD PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Uniques structure for table channel_message_list
-- ----------------------------
ALTER TABLE "api"."channel_message_list" ADD CONSTRAINT "channel_message_list_channel_id_message_id_key" UNIQUE ("channel_id","message_id") NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Foreign keys structure for table channel_message_list
-- ----------------------------
ALTER TABLE "api"."channel_message_list" ADD CONSTRAINT "channel_message_list_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "api"."channel_message" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE "api"."channel_message_list" ADD CONSTRAINT "channel_message_list_channel_id_fkey" FOREIGN KEY ("channel_id") REFERENCES "api"."channel" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;


-- ----------------------------------------------------------------------------------------
--  Structure for table ChannelParticipant
-- ----------------------------------------------------------------------------------------
-- ----------------------------
--  Primary key structure for table channel_participant
-- ----------------------------
ALTER TABLE "api"."channel_participant" ADD PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Uniques structure for table channel_participant
-- ----------------------------
ALTER TABLE "api"."channel_participant" ADD CONSTRAINT "channel_participant_channel_id_account_id_key" UNIQUE ("channel_id","account_id") NOT DEFERRABLE INITIALLY IMMEDIATE;
COMMENT ON CONSTRAINT "channel_participant_channel_id_account_id_key" ON "api"."channel_participant" IS 'An account can not participate in one channel twice';
-- ----------------------------
--  Foreign keys structure for table channel_participant
-- ----------------------------
ALTER TABLE "api"."channel_participant" ADD CONSTRAINT "channel_participant_channel_id_fkey" FOREIGN KEY ("channel_id") REFERENCES "api"."channel" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE "api"."channel_participant" ADD CONSTRAINT "channel_participant_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "api"."account" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Indexes structure for table channel_participant
-- ----------------------------
CREATE INDEX  "channel_participant_account_id_idx" ON "api"."channel_participant" USING btree(account_id ASC NULLS LAST);
CREATE INDEX  "channel_participant_channel_id_idx" ON "api"."channel_participant" USING btree(channel_id ASC NULLS LAST);
CREATE INDEX  "channel_participant_lower_idx" ON "api"."channel_participant" USING btree(lower(status_constant::text) COLLATE "default" ASC NULLS LAST);


-- ----------------------------------------------------------------------------------------
--  Structure for table Interaction
-- ----------------------------------------------------------------------------------------
-- ----------------------------
--  Primary key structure for table interaction
-- ----------------------------
ALTER TABLE "api"."interaction" ADD PRIMARY KEY ("id", "created_at", "type_constant") NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Uniques structure for table interaction
-- ----------------------------
ALTER TABLE "api"."interaction" ADD CONSTRAINT "interaction_message_id_account_id_type_constant_key" UNIQUE ("message_id","account_id","type_constant") NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Foreign keys structure for table interaction
-- ----------------------------
ALTER TABLE "api"."interaction" ADD CONSTRAINT "interaction_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "api"."channel_message" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE "api"."interaction" ADD CONSTRAINT "interaction_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "api"."account" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;


-- ----------------------------------------------------------------------------------------
--  Structure for table MessageReply
-- ----------------------------------------------------------------------------------------
-- ----------------------------
--  Primary key structure for table message_reply
-- ----------------------------
ALTER TABLE "api"."message_reply" ADD PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;

-- ----------------------------
--  Foreign keys structure for table message_reply
-- ----------------------------
ALTER TABLE "api"."message_reply" ADD CONSTRAINT "message_reply_reply_id_fkey" FOREIGN KEY ("reply_id") REFERENCES "api"."channel_message" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE "api"."message_reply" ADD CONSTRAINT "message_reply_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "api"."channel_message" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;

-- ----------------------------------------------------------------------------------------
--  Structure for table NotificationContent
-- ----------------------------------------------------------------------------------------
-- ----------------------------
--  Primary key structure for table notification_content
-- ----------------------------
ALTER TABLE "api"."notification_content" ADD PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Indexes structure for table notification_content
-- ----------------------------
CREATE UNIQUE INDEX  "notification_content_id_key" ON "api"."notification_content" USING btree("id" ASC NULLS LAST);

-- ----------------------------------------------------------------------------------------
--  Structure for table Notification
-- ----------------------------------------------------------------------------------------
-- ----------------------------
--  Primary key structure for table notification
-- ----------------------------
ALTER TABLE "api"."notification" ADD PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Foreign keys structure for table notification
-- ----------------------------
ALTER TABLE "api"."notification" ADD CONSTRAINT "notification_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "api"."account" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE "api"."notification" ADD CONSTRAINT "notification_notification_content_id_fkey" FOREIGN KEY ("notification_content_id") REFERENCES "api"."notification_content" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Indexes structure for table notification
-- ----------------------------
CREATE UNIQUE INDEX  "notification_id_key" ON "api"."notification" USING btree("id" ASC NULLS LAST);

-- ----------------------------------------------------------------------------------------
--  Structure for table Activity
-- ----------------------------------------------------------------------------------------
-- ----------------------------
--  Primary key structure for table activity
-- ----------------------------
ALTER TABLE "api"."activity" ADD PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Foreign keys structure for table activity
-- ----------------------------
ALTER TABLE "api"."activity" ADD CONSTRAINT "activity_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "api"."account" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Indexes structure for table activity
-- ----------------------------
CREATE UNIQUE INDEX  "activity_id_key" ON "api"."activity" USING btree("id" ASC NULLS LAST);

-- ----------------------------------------------------------------------------------------
--  Structure for table NotificationSubscription
-- ----------------------------------------------------------------------------------------
-- ----------------------------
--  Primary key structure for table notification_subscription
-- ----------------------------
ALTER TABLE "api"."notification_subscription" ADD PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Foreign keys structure for table notification_subscription
-- ----------------------------
ALTER TABLE "api"."notification_subscription" ADD CONSTRAINT "notification_subscription_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "api"."account" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE "api"."notification_subscription" ADD CONSTRAINT "notification_subscription_notification_content_id_fkey" FOREIGN KEY ("notification_content_id") REFERENCES "api"."notification_content" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Indexes structure for table notification_subscription
-- ----------------------------
CREATE UNIQUE INDEX  "notification_subscription_id_key" ON "api"."notification_subscription" USING btree("id" ASC NULLS LAST);