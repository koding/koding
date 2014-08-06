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
