-- ----------------------------
--  Sequence structure for notification_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "notification"."notification_id_seq";
CREATE SEQUENCE "notification"."notification_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
-- ALTER TABLE "notification"."notification_id_seq" OWNER TO "social";
GRANT USAGE ON SEQUENCE "notification"."notification_id_seq" TO "social";

-- ----------------------------
--  Sequence structure for notification_content_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "notification"."notification_content_id_seq";
CREATE SEQUENCE "notification"."notification_content_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
-- ALTER TABLE "notification"."notification_content_id_seq" OWNER TO "social";
GRANT USAGE ON SEQUENCE "notification"."notification_content_id_seq" TO "social";

-- ----------------------------
--  Sequence structure for activity_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "notification"."notification_activity_id_seq";
CREATE SEQUENCE "notification"."notification_activity_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
-- ALTER TABLE "notification"."notification_activity_id_seq" OWNER TO "social";
GRANT USAGE ON SEQUENCE "notification"."notification_activity_id_seq" TO "social";

-- ----------------------------
--  Sequence structure for notification_setting_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "notification"."notification_setting_id_seq";
CREATE SEQUENCE "notification"."notification_setting_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
-- ALTER TABLE "notification"."notification_setting_id_seq" OWNER TO "social";
GRANT USAGE ON SEQUENCE "notification"."notification_setting_id_seq" TO "social";