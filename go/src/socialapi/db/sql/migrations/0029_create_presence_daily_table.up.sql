--
-- create schema
--

DO $$
  BEGIN
    BEGIN
      CREATE SCHEMA IF NOT EXISTS presence;
    END;
  END;
$$;

GRANT usage ON SCHEMA presence to social;

--
-- create the sequence
--

DO $$
  BEGIN
    BEGIN
      CREATE SEQUENCE "presence"."daily_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
    EXCEPTION WHEN duplicate_table THEN
    END;
  END;
$$;

GRANT USAGE ON SEQUENCE "presence"."daily_id_seq" TO "social";


--
-- create presence table for storing general purpose presence definitions
--
CREATE TABLE IF NOT EXISTS "presence"."daily" (
    "id" BIGINT NOT NULL DEFAULT nextval('presence.daily_id_seq'::regclass),
    "account_id" BIGINT NOT NULL,
    "group_name" VARCHAR (200) NOT NULL CHECK ("group_name" <> ''),
    "created_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "is_processed" BOOLEAN NOT NULL DEFAULT FALSE,

    -- create constraints along with table creation
    PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE
) WITH (OIDS = FALSE);
GRANT SELECT, INSERT, UPDATE, DELETE ON "presence"."daily" TO "social";

DO $$
  BEGIN
    CREATE INDEX  "presence_daily_crea_at_acc_id_group_name_is_proc_idx" ON presence.daily USING btree(created_at DESC, account_id DESC, group_name DESC, is_processed DESC);
  EXCEPTION WHEN duplicate_table THEN
    RAISE NOTICE 'presence_daily_crea_at_acc_id_group_name_is_proc_idx already exists';
  END;
$$;
