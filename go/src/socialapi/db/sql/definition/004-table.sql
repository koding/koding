SET ROLE social;


-- ----------------------------
--  Table structure for channel
-- ----------------------------
CREATE TYPE "api"."channel_type_constant_enum" AS ENUM (
    'group',
    'topic',
    'followingfeed',
    'followers',
    'chat',
    'pinnedactivity',
    'privatemessage',
    'default'
);
ALTER TYPE "api"."channel_type_constant_enum" OWNER TO "social";

CREATE TYPE "api"."channel_privacy_constant_enum" AS ENUM (
    'public',
    'private'
);
ALTER TYPE "api"."channel_privacy_constant_enum" OWNER TO "social";

DROP TABLE IF EXISTS "api"."channel";
CREATE TABLE "api"."channel" (
    "id" bigint NOT NULL DEFAULT nextval('api.channel_id_seq'::regclass),
    "name" varchar(200) NOT NULL COLLATE "default",
    "creator_id" bigint NOT NULL,
    "group_name" varchar(200) NOT NULL COLLATE "default",
    "purpose" text COLLATE "default",
    "secret_key" text COLLATE "default",
    "type_constant" "api"."channel_type_constant_enum",
    "privacy_constant" "api"."channel_privacy_constant_enum",
    "created_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "updated_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "deleted_at" timestamp(6) WITH TIME ZONE
)
WITH (OIDS=FALSE);
-- ALTER TABLE "api"."channel" OWNER TO "socialapplication";
GRANT SELECT, INSERT, UPDATE ON "api"."channel" TO "socialapplication";


-- ----------------------------
--  Table structure for account
-- ----------------------------
DROP TABLE IF EXISTS "api"."account";
CREATE TABLE "api"."account" (
    "id" bigint NOT NULL DEFAULT nextval('api.account_id_seq'::regclass),
    "old_id" varchar(24) NOT NULL COLLATE "default"
)
WITH (OIDS=FALSE);
-- ALTER TABLE "api"."account" OWNER TO "socialapplication";
GRANT SELECT, INSERT ON "api"."account" TO "socialapplication";



-- ----------------------------
--  Table structure for channel_message
-- ----------------------------
CREATE TYPE "api"."channel_message_type_constant_enum" AS ENUM (
    'post',
    'reply',
    'join',
    'leave',
    'chat',
    'privatemessage'
);
ALTER TYPE "api"."channel_message_type_constant_enum" OWNER TO "social";

DROP TABLE IF EXISTS "api"."channel_message";
CREATE TABLE "api"."channel_message" (
    "id" bigint NOT NULL DEFAULT nextval('api.channel_message_id_seq'::regclass),
    "body" text COLLATE "default",
    "slug" varchar(100) NOT NULL COLLATE "default",
    "type_constant" "api"."channel_message_type_constant_enum",
    "account_id" bigint NOT NULL,
    "initial_channel_id" bigint NOT NULL,
    "created_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "updated_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "deleted_at" timestamp(6) WITH TIME ZONE
)
WITH (OIDS=FALSE);
-- ALTER TABLE "api"."channel_message" OWNER TO "socialapplication";
GRANT SELECT, INSERT, UPDATE ON "api"."channel_message" TO "socialapplication";


-- ----------------------------
--  Table structure for channel_message_list
-- ----------------------------
DROP TABLE IF EXISTS "api"."channel_message_list";
CREATE TABLE "api"."channel_message_list" (
    "id" bigint NOT NULL DEFAULT nextval('api.channel_message_list_id_seq'::regclass),
    "channel_id" bigint NOT NULL DEFAULT 0,
    "message_id" bigint NOT NULL DEFAULT 0,
    "added_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now()
)
WITH (OIDS=FALSE);
-- ALTER TABLE "api"."channel_message_list" OWNER TO "socialapplication";
GRANT SELECT, INSERT, UPDATE, DELETE ON "api"."channel_message_list" TO "socialapplication";

-- ----------------------------
--  Table structure for channel_participant
-- ----------------------------
CREATE TYPE "api"."channel_participant_status_constant_enum" AS ENUM (
    'active',
    'left',
    'requestpending'
);
ALTER TYPE "api"."channel_participant_status_constant_enum" OWNER TO "social";

DROP TABLE IF EXISTS "api"."channel_participant";
CREATE TABLE "api"."channel_participant" (
    "id" bigint NOT NULL DEFAULT nextval('api.channel_participant_id_seq'::regclass),
    "channel_id" bigint NOT NULL DEFAULT 0,
    "account_id" bigint NOT NULL DEFAULT 0,
    "status_constant" "api"."channel_participant_status_constant_enum",
    "last_seen_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "created_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "updated_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now()
)
WITH (OIDS=FALSE);
-- ALTER TABLE "api"."channel_participant" OWNER TO "socialapplication";
GRANT SELECT, INSERT, UPDATE ON "api"."channel_participant" TO "socialapplication";

-- ----------------------------
--  Table structure for interaction
-- ----------------------------
CREATE TYPE "api"."interaction_type_constant_enum" AS ENUM (
    'like',
    'upvote',
    'downvote'
);
ALTER TYPE "api"."interaction_type_constant_enum" OWNER TO "social";

DROP TABLE IF EXISTS "api"."interaction";
CREATE TABLE "api"."interaction" (
    "id" bigint NOT NULL DEFAULT nextval('api.interaction_id_seq'::regclass),
    "message_id" bigint NOT NULL DEFAULT 0,
    "account_id" bigint NOT NULL DEFAULT 0,
    "type_constant" "api"."interaction_type_constant_enum",
    "created_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now()
)
WITH (OIDS=FALSE);
-- ALTER TABLE "api"."interaction" OWNER TO "socialapplication";
GRANT SELECT, INSERT, DELETE ON "api"."interaction" TO "socialapplication";


-- ----------------------------
--  Table structure for message_reply
-- ----------------------------
DROP TABLE IF EXISTS "api"."message_reply";
CREATE TABLE "api"."message_reply" (
    "id" bigint NOT NULL DEFAULT nextval('api.message_reply_id_seq'::regclass),
    "message_id" bigint NOT NULL DEFAULT 0,
    "reply_id" bigint NOT NULL DEFAULT 0,
    "created_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now()
)
WITH (OIDS=FALSE);
-- ALTER TABLE "api"."message_reply" OWNER TO "socialapplication";
GRANT SELECT, INSERT, DELETE ON "api"."message_reply" TO "socialapplication";

-- ----------------------------
--  Table structure for notification
-- ----------------------------
DROP TABLE IF EXISTS "api"."notification";
CREATE TABLE "api"."notification" (
    "id" int8 NOT NULL DEFAULT nextval('notification_id_seq'::regclass),
    "account_id" int8 NOT NULL,
    "notification_content_id" int8 NOT NULL,
    "glanced" bool NOT NULL,
    "subscribed_at" timestamp(6) WITH TIME ZONE,
    "unsubscribed_at" timestamp(6) WITH TIME ZONE,
    "activated_at" timestamp(6) WITH TIME ZONE
)
WITH (OIDS=FALSE);
-- ALTER TABLE "api"."notification" OWNER TO "socialapplication";
GRANT SELECT, INSERT, DELETE ON "api"."notification" TO "socialapplication";

-- ----------------------------
--  Table structure for notification_content
-- ----------------------------
DROP TABLE IF EXISTS "api"."notification_content";
CREATE TABLE "api"."notification_content" (
    "id" int8 NOT NULL DEFAULT nextval('notification_content_id_seq'::regclass),
    "target_id" int8 NOT NULL,
    "type_constant" varchar(100) NOT NULL COLLATE "default",
    "created_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now()
)
WITH (OIDS=FALSE);
-- ALTER TABLE "api"."notification_content" OWNER TO "socialapplication";
GRANT SELECT, INSERT, DELETE ON "api"."notification_content" TO "socialapplication";

-- ----------------------------
--  Table structure for notification_activity
-- ----------------------------
DROP TABLE IF EXISTS "api"."notification_activity";
CREATE TABLE "api"."notification_activity" (
    "id" int8 NOT NULL DEFAULT nextval('notification_activity_id_seq'::regclass),
    "actor_id" int8 NOT NULL,
    "notification_content_id" int8 NOT NULL,
    "obsolete" bool NOT NULL,
    "created_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now()
)
WITH (OIDS=FALSE);
-- ALTER TABLE "api"."notification_activity" OWNER TO "socialapplication";
GRANT SELECT, INSERT, DELETE ON "api"."notification_activity" TO "socialapplication";
