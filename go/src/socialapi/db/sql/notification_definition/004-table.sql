-- ----------------------------
--  Table structure for notification
-- ----------------------------
DROP TABLE IF EXISTS "notification"."notification";
CREATE TABLE "notification"."notification" (
    "id" bigint NOT NULL DEFAULT nextval('notification.notification_id_seq'::regclass),
    "account_id" bigint NOT NULL,
    "notification_content_id" bigint NOT NULL,
    "glanced" bool NOT NULL,
    "subscribed_at" timestamp(6) WITH TIME ZONE,
    "unsubscribed_at" timestamp(6) WITH TIME ZONE,
    "activated_at" timestamp(6) WITH TIME ZONE,
    "context_channel_id" BIGINT NOT NULL
)
WITH (OIDS=FALSE);
GRANT SELECT, INSERT,DELETE, UPDATE ON "notification"."notification" TO "social";

-- ----------------------------
--  Table structure for notification_content
-- ----------------------------
CREATE TYPE "notification"."notification_content_type_constant_enum" AS ENUM (
    'like',
    'comment',
    'pm',
    'mention'
);
ALTER TYPE "notification"."notification_content_type_constant_enum" OWNER TO "social";

DROP TABLE IF EXISTS "notification"."notification_content";
CREATE TABLE "notification"."notification_content" (
    "id" bigint NOT NULL DEFAULT nextval('notification.notification_content_id_seq'::regclass),
    "target_id" bigint NOT NULL,
    "type_constant" "notification"."notification_content_type_constant_enum",
    "created_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now()
)
WITH (OIDS=FALSE);
GRANT SELECT, INSERT,DELETE ON "notification"."notification_content" TO "social";

-- ----------------------------
--  Table structure for notification_activity
-- ----------------------------
DROP TABLE IF EXISTS "notification"."notification_activity";
CREATE TABLE "notification"."notification_activity" (
    "id" bigint NOT NULL DEFAULT nextval('notification.notification_activity_id_seq'::regclass),
    "actor_id" bigint NOT NULL,
    "message_id" bigint NOT NULL,
    "notification_content_id" bigint NOT NULL,
    "obsolete" bool NOT NULL,
    "created_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now()
)
WITH (OIDS=FALSE);
GRANT SELECT, INSERT,DELETE, UPDATE ON "notification"."notification_activity" TO "social";

-- ----------------------------
--  Table structure for notification_setting
-- ----------------------------
CREATE TYPE "notification"."notification_setting_status_constant_enum" AS ENUM (
    'all',
    'personal',
    'never'
);
ALTER TYPE "notification"."notification_setting_status_constant_enum" OWNER TO "social";

DROP TABLE IF EXISTS "notification"."notification_setting";

CREATE TABLE IF NOT EXISTS "notification"."notification_setting"  (
    "id" BIGINT NOT NULL DEFAULT nextval(
        'notification.notification_setting_id_seq' :: regclass
    ),
    "channel_id" BIGINT NOT NULL,
    "account_id" BIGINT NOT NULL,
    "desktop_setting" "notification"."notification_setting_status_constant_enum",
    "mobile_setting" "notification"."notification_setting_status_constant_enum",
    "is_muted" BOOLEAN DEFAULT NULL,
    "is_suppressed" BOOLEAN DEFAULT NULL,
    "created_at" TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    "updated_at" TIMESTAMP(6) WITH TIME ZONE NOT NULL
) WITH (OIDS = FALSE);
GRANT SELECT, INSERT,UPDATE ON "notification"."notification_setting" TO "social";
