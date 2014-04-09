SET ROLE social;
-- ----------------------------
--  Table structure for channel
-- ----------------------------
DROP TABLE IF EXISTS "api"."channel";
CREATE TABLE "api"."channel" (
    "id" int8 NOT NULL DEFAULT nextval('channel_id_seq'::regclass),
    "name" varchar(200) NOT NULL COLLATE "default",
    "creator_id" int8 NOT NULL,
    "group_name" varchar(200) NOT NULL COLLATE "default",
    "purpose" text COLLATE "default",
    "secret_key" text COLLATE "default",
    "type_constant" varchar(100) NOT NULL COLLATE "default",
    "privacy_constant" varchar(100) NOT NULL COLLATE "default",
    "created_at" timestamp(6) WITH TIME ZONE NOT NULL,
    "updated_at" timestamp(6) WITH TIME ZONE NOT NULL
)
WITH (OIDS=FALSE);
ALTER TABLE "api"."channel" OWNER TO "socialapplication";

-- ----------------------------
--  Table structure for account
-- ----------------------------
DROP TABLE IF EXISTS "api"."account";
CREATE TABLE "api"."account" (
    "id" int8 NOT NULL DEFAULT nextval('account_id_seq'::regclass),
    "old_id" varchar(24) NOT NULL COLLATE "default"
)
WITH (OIDS=FALSE);
ALTER TABLE "api"."account" OWNER TO "socialapplication";

-- ----------------------------
--  Table structure for channel_message
-- ----------------------------
DROP TABLE IF EXISTS "api"."channel_message";
CREATE TABLE "api"."channel_message" (
    "id" int8 NOT NULL DEFAULT nextval('channel_message_id_seq'::regclass),
    "body" text COLLATE "default",
    "slug" varchar(100) NOT NULL COLLATE "default",
    "type_constant" varchar(100) NOT NULL COLLATE "default",
    "account_id" int8 NOT NULL,
    "initial_channel_id" int8 NOT NULL,
    "created_at" timestamp(6) WITH TIME ZONE,
    "updated_at" timestamp(6) WITH TIME ZONE
)
WITH (OIDS=FALSE);
ALTER TABLE "api"."channel_message" OWNER TO "socialapplication";

-- ----------------------------
--  Table structure for channel_message_list
-- ----------------------------
DROP TABLE IF EXISTS "api"."channel_message_list";
CREATE TABLE "api"."channel_message_list" (
    "id" int8 NOT NULL DEFAULT nextval('channel_message_list_id_seq'::regclass),
    "channel_id" int8 NOT NULL,
    "message_id" int8 NOT NULL,
    "added_at" timestamp(6) WITH TIME ZONE NOT NULL
)
WITH (OIDS=FALSE);
ALTER TABLE "api"."channel_message_list" OWNER TO "socialapplication";

-- ----------------------------
--  Table structure for channel_participant
-- ----------------------------
DROP TABLE IF EXISTS "api"."channel_participant";
CREATE TABLE "api"."channel_participant" (
    "id" int8 NOT NULL DEFAULT nextval('channel_participant_id_seq'::regclass),
    "channel_id" int8 NOT NULL,
    "account_id" int8 NOT NULL,
    "status_constant" varchar(100) NOT NULL COLLATE "default",
    "last_seen_at" timestamp(6) WITH TIME ZONE NOT NULL,
    "created_at" timestamp(6) WITH TIME ZONE NOT NULL,
    "updated_at" timestamp(6) WITH TIME ZONE NOT NULL
)
WITH (OIDS=FALSE);
ALTER TABLE "api"."channel_participant" OWNER TO "socialapplication";

-- ----------------------------
--  Table structure for interaction
-- ----------------------------
DROP TABLE IF EXISTS "api"."interaction";
CREATE TABLE "api"."interaction" (
    "id" int8 NOT NULL DEFAULT nextval('interaction_id_seq'::regclass),
    "message_id" int8 NOT NULL,
    "account_id" int8 NOT NULL,
    "type_constant" varchar(100) NOT NULL COLLATE "default",
    "created_at" timestamp(6) WITH TIME ZONE NOT NULL
)
WITH (OIDS=FALSE);
ALTER TABLE "api"."interaction" OWNER TO "socialapplication";

-- ----------------------------
--  Table structure for message_reply
-- ----------------------------
DROP TABLE IF EXISTS "api"."message_reply";
CREATE TABLE "api"."message_reply" (
    "id" int8 NOT NULL DEFAULT nextval('message_reply_id_seq'::regclass),
    "message_id" int8 NOT NULL,
    "reply_id" int8 NOT NULL,
    "created_at" timestamp(6) WITH TIME ZONE NOT NULL
)
WITH (OIDS=FALSE);
ALTER TABLE "api"."message_reply" OWNER TO "socialapplication";


