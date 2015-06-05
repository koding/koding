-- ----------------------------
--  Sequence structure for file_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "integration"."integration_id_seq";
CREATE SEQUENCE "integration"."integration_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
GRANT USAGE ON SEQUENCE "integration"."integration_id_seq" TO "social";

DROP SEQUENCE IF EXISTS "integration"."channel_integration_id_seq";
CREATE SEQUENCE "integration"."channel_integration_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
GRANT USAGE ON SEQUENCE "integration"."channel_integration_id_seq" TO "social";
