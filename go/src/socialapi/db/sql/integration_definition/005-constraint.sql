
-- ------------------------------------------------------------------------------------------
--  Structure for table Integration
-- ------------------------------------------------------------------------------------------
-- ----------------------------
--  Primary key structure for table integration
-- ----------------------------
ALTER TABLE integration.integration ADD PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Unique structure for table integration
-- ----------------------------
ALTER TABLE integration.integration ADD CONSTRAINT "integration_name" UNIQUE ("name") NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Indexes structure for table integration
-- ----------------------------

-- ----------------------------
--  Check constraints for table integration
-- ----------------------------
ALTER TABLE integration.integration ADD CONSTRAINT "interation_created_at_lte_updated_at_check" CHECK (created_at <= updated_at);

-- ------------------------------------------------------------------------------------------
--  Structure for table channel_integration
-- ------------------------------------------------------------------------------------------
-- ----------------------------
--  Primary key structure for table channel_integration
-- ----------------------------
ALTER TABLE integration.channel_integration ADD PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Uniques structure for table channel_integration
-- ----------------------------
ALTER TABLE integration.channel_integration ADD CONSTRAINT "channel_integration_token_key" UNIQUE ("token") NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Foreign keys structure for table channel_integration
-- ----------------------------
ALTER TABLE integration.channel_integration ADD CONSTRAINT "channel_integration_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES api.account (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE integration.channel_integration ADD CONSTRAINT "channel_integration_channel_id_fkey" FOREIGN KEY ("channel_id") REFERENCES api.channel (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE integration.channel_integration ADD CONSTRAINT "channel_integration_integration_id_fkey" FOREIGN KEY ("integration_id") REFERENCES integration.integration (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Indexes structure for table channel_integration
-- ----------------------------
DROP INDEX IF EXISTS "integration"."channel_integration_token_idx";
CREATE INDEX  "channel_integration_token_idx" ON integration.channel_integration USING btree(token DESC NULLS LAST);
-- ----------------------------
--  Check constraints for table channel_integration
-- ----------------------------
ALTER TABLE integration.channel_integration ADD CONSTRAINT "channel_interation_created_at_lte_updated_at_check" CHECK (created_at <= updated_at);
