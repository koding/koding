
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
ALTER TABLE integration.integration ADD CONSTRAINT "integration_title" UNIQUE ("title") NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Indexes structure for table integration
-- ----------------------------

-- ----------------------------
--  Check constraints for table integration
-- ----------------------------
ALTER TABLE integration.integration ADD CONSTRAINT "interation_created_at_lte_updated_at_check" CHECK (created_at <= updated_at);

-- ------------------------------------------------------------------------------------------
--  Structure for table Team_Integration
-- ------------------------------------------------------------------------------------------
-- ----------------------------
--  Primary key structure for table team_integration
-- ----------------------------
ALTER TABLE integration.team_integration ADD PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Uniques structure for table team_integration
-- ----------------------------
ALTER TABLE integration.team_integration ADD CONSTRAINT "team_integration_token_key" UNIQUE ("token") NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Foreign keys structure for table team_integration
-- ----------------------------
ALTER TABLE integration.team_integration ADD CONSTRAINT "team_integration_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES api.account (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE integration.team_integration ADD CONSTRAINT "team_integration_channel_id_fkey" FOREIGN KEY ("group_channel_id") REFERENCES api.channel (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE integration.team_integration ADD CONSTRAINT "team_integration_integration_id_fkey" FOREIGN KEY ("integration_id") REFERENCES integration.integration (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Indexes structure for table team_integration
-- ----------------------------

-- ----------------------------
--  Check constraints for table team_integration
-- ----------------------------
ALTER TABLE integration.team_integration ADD CONSTRAINT "team_interation_created_at_lte_updated_at_check" CHECK (created_at <= updated_at);
