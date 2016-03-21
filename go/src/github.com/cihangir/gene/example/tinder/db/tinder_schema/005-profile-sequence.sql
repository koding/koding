-- ----------------------------
--  Sequence structure for tinder_schema.profile_id
-- ----------------------------
DROP SEQUENCE IF EXISTS "tinder_schema"."profile_id_seq" CASCADE;
CREATE SEQUENCE "tinder_schema"."profile_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
GRANT USAGE ON SEQUENCE "tinder_schema"."profile_id_seq" TO "tinder_role";