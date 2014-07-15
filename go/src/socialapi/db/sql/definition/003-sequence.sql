-- ----------------------------
--  Sequence structure for account_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "api"."account_id_seq";
CREATE SEQUENCE "api"."account_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
GRANT USAGE ON SEQUENCE "api"."account_id_seq" TO "socialapplication";

-- ----------------------------
--  Sequence structure for channel_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "api"."channel_id_seq";
CREATE SEQUENCE "api"."channel_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
GRANT USAGE ON SEQUENCE "api"."channel_id_seq" TO "socialapplication";

-- ----------------------------
--  Sequence structure for channel_message_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "api"."channel_message_id_seq";
CREATE SEQUENCE "api"."channel_message_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
GRANT USAGE ON SEQUENCE "api"."channel_message_id_seq" TO "socialapplication";

-- ----------------------------
--  Sequence structure for channel_message_list_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "api"."channel_message_list_id_seq";
CREATE SEQUENCE "api"."channel_message_list_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
GRANT USAGE ON SEQUENCE "api"."channel_message_list_id_seq" TO "socialapplication";

-- ----------------------------
--  Sequence structure for channel_participant_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "api"."channel_participant_id_seq";
CREATE SEQUENCE "api"."channel_participant_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
GRANT USAGE ON SEQUENCE "api"."channel_participant_id_seq" TO "socialapplication";

-- ----------------------------
--  Sequence structure for interaction_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "api"."interaction_id_seq";
CREATE SEQUENCE "api"."interaction_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
GRANT USAGE ON SEQUENCE "api"."interaction_id_seq" TO "socialapplication";

-- ----------------------------
--  Sequence structure for message_reply_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "api"."message_reply_id_seq";
CREATE SEQUENCE "api"."message_reply_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
GRANT USAGE ON SEQUENCE "api"."message_reply_id_seq" TO "socialapplication";
