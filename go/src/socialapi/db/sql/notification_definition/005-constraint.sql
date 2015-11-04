-- ----------------------------------------------------------------------------------------
--  Structure for table NotificationContent
-- ----------------------------------------------------------------------------------------
-- ----------------------------
--  Primary key structure for table notification_content
-- ----------------------------
ALTER TABLE notification.notification_content ADD PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Indexes structure for table notification_content
-- ----------------------------

-- ----------------------------------------------------------------------------------------
--  Structure for table Notification
-- ----------------------------------------------------------------------------------------
-- ----------------------------
--  Primary key structure for table notification
-- ----------------------------
ALTER TABLE notification.notification ADD PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Foreign keys structure for table notification
-- ----------------------------
-- account relation is in different schema
ALTER TABLE notification.notification ADD CONSTRAINT "notification_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES api.account (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE notification.notification ADD CONSTRAINT "notification_notification_content_id_fkey" FOREIGN KEY ("notification_content_id") REFERENCES notification.notification_content (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Indexes structure for table notification
-- ----------------------------

-- ----------------------------------------------------------------------------------------
--  Structure for table NotificationActivity
-- ----------------------------------------------------------------------------------------
-- ----------------------------
--  Primary key structure for table notification_activity
-- ----------------------------
ALTER TABLE notification.notification_activity ADD PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Foreign keys structure for table activity
-- ----------------------------
-- account relation is in different schema
ALTER TABLE notification.notification_activity ADD CONSTRAINT "notification_activity_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES api.account (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE notification.notification_activity ADD CONSTRAINT "notification_activity_notification_content_id_fkey" FOREIGN KEY ("notification_content_id") REFERENCES notification.notification_content (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Indexes structure for table activity
-- ----------------------------
CREATE INDEX  "notification_account_id_context_id_notification_content_id_idx" ON "notification"."notification" USING btree(account_id DESC, context_channel_id DESC, notification_content_id DESC);

CREATE INDEX  "notification_activity_actor_id_content_id_obsolete_idx" ON "notification"."notification_activity" USING btree(actor_id DESC, notification_content_id DESC, obsolete);

CREATE INDEX  "notification_content_type_constant_target_id_idx" ON "notification"."notification_content" USING btree(type_constant DESC, target_id DESC);

-- ----------------------------
--  Primary key structure for table notification_setting
-- ----------------------------
ALTER TABLE notification.notification_setting ADD PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE;
-- ----------------------------
--  Foreign keys structure for table activity
-- ----------------------------
-- account relation is in different schema
ALTER TABLE notification.notification_setting ADD CONSTRAINT "notification_setting_channel_id_fkey" FOREIGN KEY ("channel_id") REFERENCES "api"."channel" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE notification.notification_setting ADD CONSTRAINT "notification_setting_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "api"."account" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;

