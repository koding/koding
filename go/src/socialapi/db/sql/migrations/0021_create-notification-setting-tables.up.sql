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
