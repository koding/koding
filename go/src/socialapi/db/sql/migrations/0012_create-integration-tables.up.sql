--
-- create schema
--

DO $$
  BEGIN
    BEGIN
      CREATE SCHEMA IF NOT EXISTS integration;
    END;
  END;
$$;

GRANT usage ON SCHEMA integration to social;

--
-- create the sequence
--

DO $$
  BEGIN
    BEGIN
      CREATE SEQUENCE "integration"."integration_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
    EXCEPTION WHEN duplicate_table THEN
    END;

    BEGIN
      CREATE SEQUENCE "integration"."channel_integration_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
    EXCEPTION WHEN duplicate_table THEN
    END;
  END;
$$;

GRANT USAGE ON SEQUENCE "integration"."integration_id_seq" TO "social";

GRANT USAGE ON SEQUENCE "integration"."channel_integration_id_seq" TO "social";

-- Create "integration"."integration_type_constant_enum"
--
-- All of this to create a type if it does not exist
CREATE OR REPLACE FUNCTION create_integration_integration_type_constant_enum_type() RETURNS integer AS $$
DECLARE v_exists INTEGER;
BEGIN
    SELECT into v_exists (SELECT 1 FROM pg_type WHERE typname = 'integration_type_constant_enum');
    IF v_exists IS NULL THEN
      CREATE TYPE "integration"."integration_type_constant_enum" AS ENUM (
        'incoming',
        'outgoing'
      );
    END IF;
    RETURN v_exists;
END;
$$ LANGUAGE plpgsql;

-- Call the function
SELECT create_integration_integration_type_constant_enum_type();
-- Remove the function
DROP function create_integration_integration_type_constant_enum_type();


DO $$
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'integration_type_constant_enum') THEN
      CREATE TYPE "integration"."integration_type_constant_enum" AS ENUM (
        'incoming',
        'outgoing'
      );
    END IF;
  END;
$$;
--
-- create integration table for storing general purpose integration definitions
--
CREATE TABLE IF NOT EXISTS "integration"."integration" (
    "id" BIGINT NOT NULL DEFAULT nextval('integration.integration_id_seq'::regclass),
    "name" VARCHAR (200) NOT NULL CHECK ("name" <> ''),
    "title" VARCHAR (200) NOT NULL COLLATE "default",
    "icon_path" VARCHAR (2000) COLLATE "default",
    "description" TEXT COLLATE "default",
    "instructions" TEXT COLLATE "default",
    "type_constant" "integration"."integration_type_constant_enum",
    "settings" hstore,
    "created_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "updated_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "deleted_at" timestamp(6) WITH TIME ZONE,

    -- create constraints along with table creation
    PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE,
    CONSTRAINT "integration_name" UNIQUE ("name") NOT DEFERRABLE INITIALLY IMMEDIATE,
    CONSTRAINT "interation_created_at_lte_updated_at_check" CHECK (created_at <= updated_at)
) WITH (OIDS = FALSE);
GRANT SELECT, INSERT, UPDATE ON "integration"."integration" TO "social";

--
-- create channel_integration table for storing integration customizations
--
CREATE TABLE IF NOT EXISTS "integration"."channel_integration" (
  "id" BIGINT NOT NULL DEFAULT nextval('integration.channel_integration_id_seq'::regclass),
  "description" VARCHAR (140) COLLATE "default",
  "token" UUID NOT NULL DEFAULT uuid_generate_v4(),
  "integration_id" BIGINT NOT NULL,
  "group_name" VARCHAR(200) NOT NULL CHECK ("group_name" <> '') COLLATE "default",
  "channel_id" BIGINT NOT NULL,
  "creator_id" BIGINT NOT NULL,
  "is_disabled" BOOLEAN NOT NULL DEFAULT TRUE,
  "settings" hstore,
  "created_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now(),
  "updated_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now(),
  "deleted_at" timestamp(6) WITH TIME ZONE,

  -- create constraints along with table creation
  PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT "channel_integration_token_key" UNIQUE ("token") NOT DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT "channel_integration_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES api.account (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT "channel_integration_channel_id_fkey" FOREIGN KEY ("channel_id") REFERENCES api.channel (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT "channel_integration_integration_id_fkey" FOREIGN KEY ("integration_id") REFERENCES integration.integration (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT "team_interation_created_at_lte_updated_at_check" CHECK (created_at <= updated_at)
) WITH (OIDS = FALSE);

GRANT SELECT, INSERT, UPDATE ON "integration"."channel_integration" TO "social";

DO $$
  BEGIN
    CREATE INDEX  "channel_integration_token_idx" ON integration.channel_integration USING btree(token DESC NULLS LAST);
  EXCEPTION WHEN duplicate_table THEN
    RAISE NOTICE 'channel_integration_token_idx already exists';
  END;
$$;


--
-- ALSO ADDED BOT channel type and channel message type
--

