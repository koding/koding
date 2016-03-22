-- SET ROLE social;

-- ----------------------------
--  General types
-- ----------------------------
CREATE TYPE "api"."role_constant_enum" AS ENUM (
    -- 'superadmin', this will be a property of the account
    'admin',
    'moderator',
    'member',
    'guest'
);

-- ----------------------------
--  Table structure for channel
-- ----------------------------
CREATE TYPE "api"."channel_type_constant_enum" AS ENUM (
    'group',
    'topic',
    'linkedtopic',
    'followingfeed',
    'followers',
    'pinnedactivity',
    'privatemessage',
    'announcement',
    'default',
    'collaboration',
    'bot'
);
ALTER TYPE "api"."channel_type_constant_enum" OWNER TO "social";

CREATE TYPE "api"."channel_privacy_constant_enum" AS ENUM (
    'public',
    'private'
);
ALTER TYPE "api"."channel_privacy_constant_enum" OWNER TO "social";

DROP TABLE IF EXISTS "api"."channel";
CREATE TABLE "api"."channel" (
    "id" BIGINT NOT NULL DEFAULT api.channel_next_id (),
    "token" UUID NOT NULL DEFAULT uuid_generate_v1(),
    "name" VARCHAR (200) NOT NULL COLLATE "default",
    "creator_id" BIGINT NOT NULL,
    "group_name" VARCHAR (200) NOT NULL COLLATE "default",
    "purpose" TEXT COLLATE "default",
    "type_constant" "api"."channel_type_constant_enum",
    "privacy_constant" "api"."channel_privacy_constant_enum",
    "meta_bits" SMALLINT NOT NULL DEFAULT 0::SMALLINT,
    "created_at" TIMESTAMP (6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "updated_at" TIMESTAMP (6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "deleted_at" TIMESTAMP (6) WITH TIME ZONE,
    "payload" hstore
) WITH (OIDS = FALSE);

-- ALTER TABLE "api"."channel" OWNER TO "social";
GRANT SELECT, INSERT, UPDATE, DELETE ON "api"."channel" TO "social";


-- ----------------------------
--  Table structure for account
-- ----------------------------
DROP TABLE IF EXISTS "api"."account";
CREATE TABLE "api"."account" (
    "id" BIGINT NOT NULL DEFAULT nextval('api.account_id_seq' :: regclass),
    "old_id" VARCHAR (24) NOT NULL COLLATE "default",
    "is_troll" BOOLEAN NOT NULL DEFAULT FALSE,
    "nick" VARCHAR (25) NOT NULL CHECK ("nick" <> ''),
    "settings" HSTORE
) WITH (OIDS = FALSE);

-- ALTER TABLE "api"."account" OWNER TO "social";
GRANT SELECT, INSERT, UPDATE ON "api"."account" TO "social";



-- ----------------------------
--  Table structure for channel_message
-- ----------------------------
CREATE TYPE "api"."channel_message_type_constant_enum" AS ENUM (
    'post',
    'reply',
    'join',
    'leave',
    'privatemessage',
    'bot',
    'system'
);

ALTER TYPE "api"."channel_message_type_constant_enum" OWNER TO "social";

DROP TABLE IF EXISTS "api"."channel_message";
CREATE TABLE "api"."channel_message" (
    "id" BIGINT NOT NULL DEFAULT api.channel_message_next_id (),
    "token" UUID NOT NULL DEFAULT uuid_generate_v1(),
    "body" TEXT COLLATE "default",
    -- TODO ADD CHECK FOR SPACE CHAR
    "slug" VARCHAR (100) NOT NULL COLLATE "default",
    "type_constant" "api"."channel_message_type_constant_enum",
    "account_id" BIGINT NOT NULL,
    "initial_channel_id" BIGINT NOT NULL,
    "meta_bits" SMALLINT NOT NULL DEFAULT 0 :: SMALLINT,
    "created_at" TIMESTAMP (6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "updated_at" TIMESTAMP (6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "deleted_at" TIMESTAMP (6) WITH TIME ZONE,
    "payload" hstore
) WITH (OIDS = FALSE);
GRANT SELECT, INSERT, UPDATE, DELETE ON "api"."channel_message" TO "social";


-- ----------------------------
--  Table structure for channel_message_list
-- ----------------------------
DROP TABLE IF EXISTS "api"."channel_message_list";
CREATE TABLE "api"."channel_message_list" (
    "id" BIGINT NOT NULL DEFAULT nextval(
        'api.channel_message_list_id_seq' :: regclass
    ),
    "channel_id" BIGINT NOT NULL DEFAULT 0,
    "message_id" BIGINT NOT NULL DEFAULT 0,
    "meta_bits" SMALLINT NOT NULL DEFAULT 0 :: SMALLINT,
    "added_at" TIMESTAMP (6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "revised_at" TIMESTAMP (6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "deleted_at" TIMESTAMP (6) WITH TIME ZONE
) WITH (OIDS = FALSE);

-- ALTER TABLE "api"."channel_message_list" OWNER TO "social";
GRANT SELECT, INSERT, UPDATE, DELETE ON "api"."channel_message_list" TO "social";

-- ----------------------------
--  Table structure for channel_participant
-- ----------------------------
CREATE TYPE "api"."channel_participant_status_constant_enum" AS ENUM (
    'active',
    'left',
    'requestpending',
    'blocked'
);

ALTER TYPE "api"."channel_participant_status_constant_enum" OWNER TO "social";

DROP TABLE IF EXISTS "api"."channel_participant";
CREATE TABLE "api"."channel_participant" (
    "id" BIGINT NOT NULL DEFAULT nextval(
        'api.channel_participant_id_seq' :: regclass
    ),
    "channel_id" BIGINT NOT NULL DEFAULT 0,
    "account_id" BIGINT NOT NULL DEFAULT 0,
    "status_constant" "api"."channel_participant_status_constant_enum",
    -- "role_constant" "api"."role_constant_enum",
    "meta_bits" SMALLINT NOT NULL DEFAULT 0 :: SMALLINT,
    "last_seen_at" TIMESTAMP (6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "created_at" TIMESTAMP (6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "updated_at" TIMESTAMP (6) WITH TIME ZONE NOT NULL DEFAULT now()
) WITH (OIDS = FALSE);

-- ALTER TABLE "api"."channel_participant" OWNER TO "social";
GRANT SELECT, INSERT, UPDATE, DELETE ON "api"."channel_participant" TO "social";

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
    "id" BIGINT NOT NULL DEFAULT nextval(
        'api.interaction_id_seq' :: regclass
    ),
    "message_id" BIGINT NOT NULL DEFAULT 0,
    "account_id" BIGINT NOT NULL DEFAULT 0,
    "type_constant" "api"."interaction_type_constant_enum",
    "meta_bits" SMALLINT NOT NULL DEFAULT 0 :: SMALLINT,
    "created_at" TIMESTAMP (6) WITH TIME ZONE NOT NULL DEFAULT now()
) WITH (OIDS = FALSE);

-- ALTER TABLE "api"."interaction" OWNER TO "social";
-- remove update permission from social
-- this is added for trollmode worker, but it can use another user for extensive permission required operations
GRANT SELECT, UPDATE, INSERT, DELETE ON "api"."interaction" TO "social";


-- ----------------------------
--  Table structure for message_reply
-- ----------------------------
DROP TABLE IF EXISTS "api"."message_reply";
CREATE TABLE "api"."message_reply" (
    "id" BIGINT NOT NULL DEFAULT nextval(
        'api.message_reply_id_seq' :: regclass
    ),
    "message_id" BIGINT NOT NULL DEFAULT 0,
    "reply_id" BIGINT NOT NULL DEFAULT 0,
    "meta_bits" SMALLINT NOT NULL DEFAULT 0 :: SMALLINT,
    "created_at" TIMESTAMP (6) WITH TIME ZONE NOT NULL DEFAULT now()
) WITH (OIDS = FALSE);

-- ALTER TABLE "api"."message_reply" OWNER TO "social";
GRANT SELECT, UPDATE, INSERT, DELETE ON "api"."message_reply" TO "social";

-- ----------------------------
--  Table structure for permission
-- ----------------------------
-- CREATE TYPE "api"."permission_status_constant_enum" AS ENUM (
--     'allowed',
--     'disallowed'
-- );

-- DROP TABLE IF EXISTS "api"."permission";
-- CREATE TABLE "api"."permission" (
--     "id" BIGINT NOT NULL DEFAULT nextval(
--         'api.permission_id_seq' :: regclass
--     ),
--     "name" VARCHAR(200) NOT NULL COLLATE "default",
--     "channel_id" BIGINT NOT NULL,
--     "role_constant" "api"."role_constant_enum",
--     "status_constant" "api"."permission_status_constant_enum",
--     "created_at" TIMESTAMP(6) WITH TIME ZONE NOT NULL,
--     "updated_at" TIMESTAMP(6) WITH TIME ZONE NOT NULL
-- ) WITH (OIDS=FALSE);
-- GRANT SELECT, INSERT, UPDATE ON "api"."permission" TO "social";


-- ----------------------------
--  Table structure for channel_link
-- ----------------------------
DROP TABLE IF EXISTS "api"."channel_link";
CREATE TABLE "api"."channel_link" (
    "id" BIGINT NOT NULL DEFAULT nextval(
        'api.channel_link_id_seq' :: regclass
    ),
    "root_id" BIGINT NOT NULL,
    "leaf_id" BIGINT NOT NULL,
    "created_at" TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    "is_finished" BOOLEAN NOT NULL DEFAULT FALSE
) WITH (OIDS=FALSE);
-- give required channel_link permissions
GRANT SELECT,UPDATE, INSERT, DELETE ON "api"."channel_link" TO "social";
