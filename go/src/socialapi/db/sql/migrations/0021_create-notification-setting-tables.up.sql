DO $$
  BEGIN
    BEGIN
      CREATE SCHEMA IF NOT EXISTS notification;
    END;
  END;
$$;

GRANT usage ON SCHEMA integration to social;

DO $$
  BEGIN
    BEGIN
      CREATE SEQUENCE "notification"."notification_settings_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
    EXCEPTION WHEN duplicate_table THEN
      RAISE NOTICE 'notification.notification_settings_id_seq sequence already exists';
    END;
  END;
$$;

GRANT USAGE ON SEQUENCE "notification"."notification_settings_id_seq" TO "social";

CREATE TABLE IF NOT EXISTS "notification"."notification_settings"  (
    "id" BIGINT NOT NULL DEFAULT nextval(
        'notification.channel_link_id_seq' :: regclass
    ),
    "channel_id" BIGINT NOT NULL,
    "account_id" BIGINT NOT NULL,
    "desktop_setting" TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    "mobile_setting" TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    "is_muted" BOOLEAN NOT NULL DEFAULT FALSE,
    "is_suppressed" BOOLEAN NOT NULL DEFAULT FALSE,
    "created_at" TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    "updated_at" TIMESTAMP(6) WITH TIME ZONE NOT NULL,

    -- create constraints along with table creation
    PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE,
    CONSTRAINT "notification_settings_channel_id_fkey" FOREIGN KEY ("channel_id") REFERENCES "notification"."channel" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE,
    CONSTRAINT "notification_settings_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "notification"."channel" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE,
    CONSTRAINT "channel_link_root_id_leaf_id_key" UNIQUE ("root_id","leaf_id") NOT DEFERRABLE INITIALLY IMMEDIATE
) WITH (OIDS=FALSE);

-- give required channel_link permissions
GRANT SELECT, INSERT, DELETE ON "notification"."channel_link" TO "social";
