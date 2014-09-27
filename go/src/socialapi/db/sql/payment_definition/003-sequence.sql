-- ----------------------------
--  Sequence structure for customer_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "payment"."customer_id_seq";
CREATE SEQUENCE "payment"."customer_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
GRANT USAGE ON SEQUENCE "payment"."customer_id_seq" TO "social";

-- ----------------------------
--  Sequence structure for plan_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "payment"."plan_id_seq";
CREATE SEQUENCE "payment"."plan_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
GRANT USAGE ON SEQUENCE "payment"."plan_id_seq" TO "social";

-- ----------------------------
--  Sequence structure for subscription_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "payment"."subscription_id_seq";
CREATE SEQUENCE "payment"."subscription_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
GRANT USAGE ON SEQUENCE "payment"."subscription_id_seq" TO "social";
