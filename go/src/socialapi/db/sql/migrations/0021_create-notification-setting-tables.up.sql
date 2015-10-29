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
      CREATE SEQUENCE "notification"."notification_settings_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
    EXCEPTION WHEN duplicate_table THEN
      RAISE NOTICE 'notification.notification_settings_id_seq sequence already exists';
    END;
  END;
$$;

DO $$
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_settings_status_constant_enum') THEN
      CREATE TYPE "notification"."notification_settings_status_constant_enum" AS ENUM (
        'all',
        'personal',
        'never'
      );
    END IF;
  END;
$$;

ALTER TYPE "notification"."notification_settings_status_constant_enum" OWNER TO "social";

CREATE TABLE IF NOT EXISTS "notification"."notification_settings"  (
    "id" BIGINT NOT NULL DEFAULT nextval(
        'notification.notification_settings_id_seq' :: regclass
    ),
    "channel_id" BIGINT NOT NULL,
    "account_id" BIGINT NOT NULL,
    "desktop_setting" "notification"."notification_settings_status_constant_enum",
    "mobile_setting" "notification"."notification_settings_status_constant_enum",
    "is_muted" BOOLEAN NOT NULL DEFAULT FALSE,
    "is_suppressed" BOOLEAN NOT NULL DEFAULT FALSE,
    "created_at" TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    "updated_at" TIMESTAMP(6) WITH TIME ZONE NOT NULL,

    -- create constraints along with table creation
    PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE,
    CONSTRAINT "notification_settings_channel_id_fkey" FOREIGN KEY ("channel_id") REFERENCES "api"."channel" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE,
    CONSTRAINT "notification_settings_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "api"."account" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE
) WITH (OIDS = FALSE);

-- give required notification_settings permissions
GRANT SELECT, INSERT,UPDATE ON "notification"."notification_settings" TO "social";
