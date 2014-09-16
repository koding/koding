-- SET ROLE social;

-- ----------------------------
--  Table structure for channel
-- ----------------------------
CREATE TYPE "api"."channel_type_constant_enum" AS ENUM (
    'group',
    'topic',
    'followingfeed',
    'followers',
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
    "deleted_at" TIMESTAMP (6) WITH TIME ZONE
) WITH (OIDS = FALSE);

-- ALTER TABLE "api"."channel" OWNER TO "social";
GRANT SELECT, INSERT, UPDATE ON "api"."channel" TO "social";


-- ----------------------------
--  Table structure for account
-- ----------------------------
DROP TABLE IF EXISTS "api"."account";
CREATE TABLE "api"."account" (
    "id" BIGINT NOT NULL DEFAULT nextval('api.account_id_seq' :: regclass),
    "old_id" VARCHAR (24) NOT NULL COLLATE "default",
    "is_troll" BOOLEAN NOT NULL DEFAULT FALSE,
    "nick" VARCHAR (25) NOT NULL CHECK ("nick" <> '')
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
    'privatemessage'
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
GRANT SELECT, INSERT, UPDATE ON "api"."channel_message" TO "social";


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
    'requestpending'
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
    "meta_bits" SMALLINT NOT NULL DEFAULT 0 :: SMALLINT,
    "last_seen_at" TIMESTAMP (6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "created_at" TIMESTAMP (6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "updated_at" TIMESTAMP (6) WITH TIME ZONE NOT NULL DEFAULT now()
) WITH (OIDS = FALSE);

-- ALTER TABLE "api"."channel_participant" OWNER TO "social";
GRANT SELECT, INSERT, UPDATE ON "api"."channel_participant" TO "social";

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
--  Table structure for payment_customer
-- ----------------------------
CREATE TYPE "api"."payment_provider" AS ENUM (
    'stripe',
    'paypal'
);
ALTER TYPE "api"."payment_provider" OWNER TO "social";

DROP TABLE IF EXISTS "api"."payment_customer";
CREATE TABLE "api"."payment_customer" (
    "id" BIGINT NOT NULL DEFAULT nextval(
        'api.payment_customer_id_seq' :: regclass
    ),
    "provider"             "api"."payment_provider",
    "provider_customer_id" VARCHAR (200) NOT NULL COLLATE "default",
    "old_id"               VARCHAR (200) NOT NULL COLLATE "default",

    "created_at" TIMESTAMP (6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "updated_at" TIMESTAMP (6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "deleted_at" TIMESTAMP (6) WITH TIME ZONE
) WITH (OIDS = FALSE);

GRANT SELECT, UPDATE, INSERT, DELETE ON "api"."payment_customer" TO "social";

-- ----------------------------
--  Table structure for payment_plan
-- ----------------------------
CREATE TYPE "api"."payment_plan_interval" AS ENUM (
    'month',
    'year'
);
ALTER TYPE "api"."payment_plan_interval" OWNER TO "social";

CREATE TYPE "api"."payment_plan_title" AS ENUM (
    'free',
    'hobbyist',
    'developer',
    'professional'
);
ALTER TYPE "api"."payment_plan_interval" OWNER TO "social";

DROP TABLE IF EXISTS "api"."payment_plan";
CREATE TABLE "api"."payment_plan" (
    "id" BIGINT NOT NULL DEFAULT nextval(
        'api.payment_plan_id_seq' :: regclass
    ),
    "interval"         "api"."payment_plan_interval",
    "title"            "api"."payment_plan_title",
    "provider"         "api"."payment_provider",
    "provider_plan_id" VARCHAR (200) NOT NULL COLLATE "default",
    "amount_in_cents"  BIGINT NOT NULL DEFAULT 0,

    "created_at" TIMESTAMP (6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "updated_at" TIMESTAMP (6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "deleted_at" TIMESTAMP (6) WITH TIME ZONE
) WITH (OIDS = FALSE);

GRANT SELECT, UPDATE, INSERT, DELETE ON "api"."payment_plan" TO "social";

-- ----------------------------
--  Table structure for payment_subscription
-- ----------------------------
CREATE TYPE "api"."payment_subscription_state" AS ENUM (
    'active',
    'expired'
);
ALTER TYPE "api"."payment_subscription_state" OWNER TO "social";

DROP TABLE IF EXISTS "api"."payment_subscription";
CREATE TABLE "api"."payment_subscription" (
    "id" BIGINT NOT NULL DEFAULT nextval(
        'api.payment_subscription_id_seq' :: regclass
    ),
    "state"                    "api"."payment_subscription_state",
    "provider"                 "api"."payment_provider",
    "provider_subscription_id" VARCHAR (200) NOT NULL COLLATE "default",
    "provider_token"           VARCHAR (200) NOT NULL COLLATE "default",
    "customer_id"              BIGINT NOT NULL DEFAULT 0,
    "plan_id"                  BIGINT NOT NULL DEFAULT 0,
    "amount_in_cents"          BIGINT NOT NULL DEFAULT 0,

    "created_at"      TIMESTAMP (6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "updated_at"      TIMESTAMP (6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "deleted_at"      TIMESTAMP (6) WITH TIME ZONE,
    "expired_at"      TIMESTAMP (6) WITH TIME ZONE,
    "canceled_at"     TIMESTAMP (6) WITH TIME ZONE
) WITH (OIDS = FALSE);

GRANT SELECT, UPDATE, INSERT, DELETE ON "api"."payment_subscription" TO "social";
