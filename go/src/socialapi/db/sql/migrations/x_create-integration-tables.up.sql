--
-- create schema
--

DO $$
  BEGIN
    BEGIN
      CREATE SCHEMA integration;

    END;
  END;
$$;

GRANT usage ON SCHEMA integration to socialapplication;

--
-- create the sequence
--

DO $$
  BEGIN
    BEGIN
      CREATE SEQUENCE "integration"."integration_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
    END;
      CREATE SEQUENCE "integration"."team_integration_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
  END;
$$;

GRANT USAGE ON SEQUENCE "integration"."integration_id_seq" TO "socialapplication";

GRANT USAGE ON SEQUENCE "integration"."team_integration_id_seq" TO "socialapplication";

CREATE TYPE "integration"."integration_type_constant_enum" AS ENUM (
  'incoming',
  'outgoing'
);
--
-- create integration table for storing general purpose integration definitions
--
CREATE TABLE "integration"."integration" (
    "id" BIGINT NOT NULL DEFAULT nextval('integration.integration_id_seq'::regclass),
    "title" VARCHAR (200) NOT NULL COLLATE "default",
    "icon_path" VARCHAR (200) COLLATE "default",
    "description" TEXT COLLATE "default",
    "instructions" TEXT COLLATE "default",
    "type_constant" "integration"."integration_type_constant_enum",
    "version" VARCHAR(6) NOT NULL COLLATE "default",
    "created_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "updated_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "deleted_at" timestamp(6) WITH TIME ZONE NOT NULL,

    -- create constraints along with table creation
    PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE,
    CONSTRAINT "integration_title" UNIQUE ("title") NOT DEFERRABLE INITIALLY IMMEDIATE,
    CONSTRAINT "interation_created_at_lte_updated_at_check" CHECK (created_at <= updated_at)
) WITH (OIDS = FALSE);
GRANT SELECT, INSERT, UPDATE ON "integration"."integration" TO "social";

--
-- create team_integration table for storing integration customizations
--
CREATE TABLE "integration"."team_integration" (
  "id" BIGINT NOT NULL DEFAULT nextval('integration.team_integration_id_seq'::regclass),
  "bot_name" VARCHAR (200) COLLATE "default",
  "bot_icon_path" VARCHAR (200) COLLATE "default",
  "description" VARCHAR (140) COLLATE "default",
  "token" VARCHAR(20) NOT NULL,
  "integration_id" BIGINT NOT NULL,
  "group_channel_id" BIGINT NOT NULL,
  "creator_id" BIGINT NOT NULL,
  "is_disabled" BOOLEAN NOT NULL DEFAULT TRUE,
  "created_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now(),
  "updated_at" timestamp(6) WITH TIME ZONE NOT NULL DEFAULT now(),
  "deleted_at" timestamp(6) WITH TIME ZONE NOT NULL,

  -- create constraints along with table creation
  PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT "team_integration_token_key" UNIQUE ("token") NOT DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT "team_integration_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES api.account (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT "team_integration_channel_id_fkey" FOREIGN KEY ("group_channel_id") REFERENCES api.channel (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT "team_integration_integration_id_fkey" FOREIGN KEY ("integration_id") REFERENCES integration.integration (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE,
  CONSTRAINT "team_interation_created_at_lte_updated_at_check" CHECK (created_at <= updated_at)
) WITH (OIDS = FALSE);

GRANT SELECT, INSERT, UPDATE ON "integration"."team_integration" TO "social";
