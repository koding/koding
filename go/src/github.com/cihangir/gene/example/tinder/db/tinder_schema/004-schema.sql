-- ----------------------------
--  Schema structure for tinder_schema
-- ----------------------------
CREATE SCHEMA IF NOT EXISTS "tinder_schema";
--
-- Give usage permission
--
GRANT usage ON SCHEMA "tinder_schema" to "tinder_role";
--
-- add new schema to search path -just for convenience
-- SELECT set_config('search_path', current_setting('search_path') || ',tinder_schema', false);