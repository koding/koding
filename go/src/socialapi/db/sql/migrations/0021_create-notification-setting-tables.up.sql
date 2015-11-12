DO $$
  BEGIN
    BEGIN
      CREATE SCHEMA IF NOT EXISTS notification;
    END;
  END;
$$;

GRANT usage ON SCHEMA notification to social;

DO $$
  BEGIN
    BEGIN
      CREATE SEQUENCE "notification"."notification_setting_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
    EXCEPTION WHEN duplicate_table THEN
      RAISE NOTICE 'notification.notification_setting_id_seq sequence already exists';
    END;
  END;
$$;

DO $$
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_setting_status_constant_enum') THEN
      CREATE TYPE "notification"."notification_setting_status_constant_enum" AS ENUM (
        'all',
        'personal',
        'never'
      );
    END IF;
  END;
$$;

ALTER TYPE "notification"."notification_setting_status_constant_enum" OWNER TO "social";

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
    "updated_at" TIMESTAMP(6) WITH TIME ZONE NOT NULL,

    -- create constraints along with table creation
    PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE,
    CONSTRAINT "notification_setting_channel_id_fkey" FOREIGN KEY ("channel_id") REFERENCES "api"."channel" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE,
    CONSTRAINT "notification_setting_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "api"."account" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE
) WITH (OIDS = FALSE);

-- give required notification_setting permissions
GRANT SELECT, INSERT,DELETE,UPDATE ON "notification"."notification_setting" TO "social";
