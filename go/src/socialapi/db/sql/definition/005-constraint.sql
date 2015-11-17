-- Table Structure should be in the following format
-- 1 Primary Keys
-- 2 Unique Keys
-- 3 Foreign Keys
-- 4 Indexes
-- SET ROLE social;


-- ------------------------------------------------------------------------------------------
--  Structure for table Account
-- ------------------------------------------------------------------------------------------
-- ----------------------------
--  Primary key structure for table account
-- ----------------------------
ALTER TABLE api.account ADD PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Uniques structure for table account
-- ----------------------------
ALTER TABLE api.account ADD CONSTRAINT "account_old_id_key" UNIQUE ("old_id") NOT DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE api.account ADD CONSTRAINT "account_nick_key" UNIQUE ("nick") NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Indexes structure for table account
-- ----------------------------

-- ------------------------------------------------------------------------------------------
--  Structure for table Channel
-- ------------------------------------------------------------------------------------------
-------------------------------
--  Primary key structure for table channel
-- ----------------------------
ALTER TABLE api.channel ADD PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Unique structure for table channel
-- ----------------------------
ALTER TABLE api.channel ADD CONSTRAINT "channel_name_group_name_type_constant_key" UNIQUE ("name","group_name","type_constant") NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Foreign keys structure for table channel
-- ----------------------------
ALTER TABLE api.channel ADD CONSTRAINT "channel_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES api.account (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Indexes structure for table channel
-- ----------------------------
DROP INDEX IF EXISTS "api"."channel_deleted_at_group_name_type_constant_creator_id_idx";
CREATE INDEX "channel_deleted_at_group_name_type_constant_creator_id_idx" ON "api"."channel" USING btree (deleted_at ASC NULLS FIRST, group_name DESC NULLS FIRST, type_constant DESC NULLS FIRST, creator_id DESC NULLS FIRST);

DROP INDEX IF EXISTS "api"."channel_group_name_type_constant_deleted_at_idx";
CREATE INDEX "channel_group_name_type_constant_deleted_at_idx" ON "api"."channel" USING btree (group_name DESC NULLS FIRST, type_constant DESC NULLS FIRST, deleted_at DESC NULLS FIRST);

-- ----------------------------
--  Check constraints for table channel
-- ----------------------------
ALTER TABLE api.channel ADD CONSTRAINT "channel_created_at_lte_updated_at_check" CHECK (created_at <= updated_at);

-- ------------------------------------------------------------------------------------------
--  Structure for table ChannelMessage
-- ------------------------------------------------------------------------------------------
-- ----------------------------
--  Primary key structure for table channel_message
-- ----------------------------
ALTER TABLE api.channel_message ADD PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Foreign keys structure for table channel_message
-- ----------------------------
ALTER TABLE api.channel_message ADD CONSTRAINT "channel_message_initial_channel_id_fkey" FOREIGN KEY ("initial_channel_id") REFERENCES api.channel (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE api.channel_message ADD CONSTRAINT "channel_message_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES api.account (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Indexes structure for table channel_message
-- ----------------------------
DROP INDEX IF EXISTS "api"."channel_message_i_c_id_t_const_a_id_c_at_d_at_idx";
CREATE INDEX "channel_message_i_c_id_t_const_a_id_c_at_d_at_idx" ON "api"."channel_message" USING btree (initial_channel_id DESC NULLS LAST,type_constant DESC NULLS LAST,account_id DESC NULLS LAST,created_at DESC NULLS LAST,deleted_at DESC NULLS LAST);

DROP INDEX IF EXISTS "api"."channel_message_slug_deleted_at_meta_bits_idx";
CREATE INDEX "channel_message_slug_deleted_at_meta_bits_idx" ON "api"."channel_message" USING btree(slug DESC NULLS LAST, deleted_at DESC NULLS FIRST, meta_bits ASC NULLS LAST);
-- ----------------------------
--  Check constraints for table channel_message
-- ----------------------------
ALTER TABLE api.channel_message ADD CONSTRAINT "channel_message_created_at_lte_updated_at_check" CHECK (created_at <= updated_at);


-- ----------------------------------------------------------------------------------------
--  Structure for table ChannelMessageList
-- ----------------------------------------------------------------------------------------
-- ----------------------------
--  Primary key structure for table channel_message_list
-- ----------------------------
ALTER TABLE api.channel_message_list ADD PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Uniques structure for table channel_message_list
-- ----------------------------
ALTER TABLE api.channel_message_list ADD CONSTRAINT "channel_message_list_channel_id_message_id_key" UNIQUE ("channel_id","message_id") NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Foreign keys structure for table channel_message_list
-- ----------------------------
ALTER TABLE api.channel_message_list ADD CONSTRAINT "channel_message_list_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES api.channel_message (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE api.channel_message_list ADD CONSTRAINT "channel_message_list_channel_id_fkey" FOREIGN KEY ("channel_id") REFERENCES api.channel (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Indexes structure for table channel_message_list
-- ----------------------------
DROP INDEX IF EXISTS "api"."channel_message_list_channel_id_idx";
CREATE INDEX  "channel_message_list_channel_id_idx" ON api.channel_message_list USING btree(channel_id DESC NULLS LAST);

DROP INDEX IF EXISTS "api"."channel_message_list_channel_id_message_id_deleted_at_idx";
CREATE INDEX  "channel_message_list_channel_id_message_id_deleted_at_idx" ON "api"."channel_message_list" USING btree(deleted_at ASC NULLS LAST, channel_id DESC, message_id DESC);

DROP INDEX IF EXISTS "api"."channel_message_list_added_at_idx";
CREATE INDEX  "channel_message_list_added_at_idx" ON "api"."channel_message_list" USING btree(added_at DESC NULLS FIRST);

-- ----------------------------------------------------------------------------------------
--  Structure for table ChannelParticipant
-- ----------------------------------------------------------------------------------------
-- ----------------------------
--  Primary key structure for table channel_participant
-- ----------------------------
ALTER TABLE api.channel_participant ADD PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Uniques structure for table channel_participant
-- ----------------------------
ALTER TABLE api.channel_participant ADD CONSTRAINT "channel_participant_channel_id_account_id_key" UNIQUE ("channel_id","account_id") NOT DEFERRABLE INITIALLY IMMEDIATE;
COMMENT ON CONSTRAINT "channel_participant_channel_id_account_id_key" ON api.channel_participant IS 'An account can not participate in one channel twice';
-- ----------------------------
--  Foreign keys structure for table channel_participant
-- ----------------------------
ALTER TABLE api.channel_participant ADD CONSTRAINT "channel_participant_channel_id_fkey" FOREIGN KEY ("channel_id") REFERENCES api.channel (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE api.channel_participant ADD CONSTRAINT "channel_participant_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES api.account (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Indexes structure for table channel_participant
-- ----------------------------
-- CREATE INDEX  "channel_participant_account_id_idx" ON api.channel_participant USING btree(account_id ASC NULLS LAST);
-- CREATE INDEX  "channel_participant_channel_id_idx" ON api.channel_participant USING btree(channel_id ASC NULLS LAST);
-- CREATE INDEX  "channel_participant_lower_idx" ON api.channel_participant USING btree(status_constant);
DROP INDEX IF EXISTS "api"."channel_participant_channel_id_status_constant_meta_bits_idx";
CREATE INDEX  "channel_participant_channel_id_status_constant_meta_bits_idx" ON "api"."channel_participant" USING btree(channel_id DESC, status_constant ASC, meta_bits ASC);
DROP INDEX IF EXISTS "api"."channel_participant_channel_id_idx";
CREATE INDEX  "channel_participant_channel_id_idx" ON "api"."channel_participant" USING btree(channel_id DESC NULLS LAST);
-- ----------------------------
--  Check constraints for table channel_participant
-- ----------------------------
ALTER TABLE api.channel_participant ADD CONSTRAINT "channel_participant_created_at_lte_updated_at_check" CHECK (created_at <= updated_at);


-- ----------------------------------------------------------------------------------------
--  Structure for table Interaction
-- ----------------------------------------------------------------------------------------
-- ----------------------------
--  Primary key structure for table interaction
-- ----------------------------
ALTER TABLE api.interaction ADD PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Uniques structure for table interaction
-- ----------------------------
ALTER TABLE api.interaction ADD CONSTRAINT "interaction_message_id_account_id_type_constant_key" UNIQUE ("message_id","account_id","type_constant") NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Foreign keys structure for table interaction
-- ----------------------------
ALTER TABLE api.interaction ADD CONSTRAINT "interaction_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES api.channel_message (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE api.interaction ADD CONSTRAINT "interaction_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES api.account (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Indexes structure for table interaction
-- ----------------------------
CREATE INDEX  "interaction_message_id_account_id_type_constant_meta_bits_idx" ON "api"."interaction" USING btree(message_id DESC, account_id DESC, type_constant ASC, meta_bits ASC);

-- ----------------------------------------------------------------------------------------
--  Structure for table MessageReply
-- ----------------------------------------------------------------------------------------
-- ----------------------------
--  Primary key structure for table message_reply
-- ----------------------------
ALTER TABLE api.message_reply ADD PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Foreign keys structure for table message_reply
-- ----------------------------
ALTER TABLE api.message_reply ADD CONSTRAINT "message_reply_reply_id_fkey" FOREIGN KEY ("reply_id") REFERENCES api.channel_message (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE api.message_reply ADD CONSTRAINT "message_reply_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES api.channel_message (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;

-- ----------------------------
--  Indexes structure for table message_reply
-- ----------------------------
CREATE INDEX  "message_reply_message_id_meta_bit_created_at" ON "api"."message_reply" USING btree(message_id DESC, meta_bits ASC, created_at ASC);



-- -- ----------------------------
-- --  Structure for table Permission
-- -- ----------------------------
-- --
-- -- ----------------------------
-- --  Primary key structure for table permission
-- -- ----------------------------
-- ALTER TABLE "api"."permission" ADD PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;

-- -- ----------------------------
-- --  Uniques structure for table permission
-- -- ----------------------------
-- ALTER TABLE "api"."permission" ADD CONSTRAINT "permission_name_channel_id_role_constant_key" UNIQUE ("name","channel_id","role_constant") NOT DEFERRABLE INITIALLY IMMEDIATE;

-- -- ----------------------------
-- --  Foreign keys structure for table permission
-- -- ----------------------------
-- ALTER TABLE "api"."permission" ADD CONSTRAINT "permission_channel_id_fkey" FOREIGN KEY ("channel_id") REFERENCES "api"."channel" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;



-- ----------------------------
--  Structure for table ChannelLink
-- ----------------------------
--
-- ----------------------------
--  Primary key structure for table channel_link
-- ----------------------------
ALTER TABLE "api"."channel_link" ADD PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;

-- ----------------------------
--  Uniques structure for table channel_link
-- ----------------------------
ALTER TABLE "api"."channel_link" ADD CONSTRAINT "channel_link_root_id_leaf_id_key" UNIQUE ("root_id","leaf_id") NOT DEFERRABLE INITIALLY IMMEDIATE;

-- ----------------------------
--  Foreign keys structure for table channel_link
-- ----------------------------
ALTER TABLE "api"."channel_link" ADD  CONSTRAINT "channel_link_root_id_fkey" FOREIGN KEY ("root_id") REFERENCES "api"."channel" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE "api"."channel_link" ADD  CONSTRAINT "channel_link_leaf_id_fkey" FOREIGN KEY ("leaf_id") REFERENCES "api"."channel" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
