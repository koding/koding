GRANT SELECT, INSERT, UPDATE, DELETE ON "sitemap"."file" TO "social";
GRANT USAGE ON SEQUENCE "sitemap"."file_id_seq" TO "social";
GRANT usage ON SCHEMA sitemap to social;
GRANT usage ON SCHEMA payment to social;
GRANT SELECT, INSERT, UPDATE ON "notification"."notification" TO "social";
GRANT SELECT, INSERT ON "notification"."notification_content" TO "social";
GRANT SELECT, INSERT, UPDATE ON "notification"."notification_activity" TO "social";
GRANT USAGE ON SEQUENCE "notification"."notification_id_seq" TO "social";
GRANT USAGE ON SEQUENCE "notification"."notification_content_id_seq" TO "social";
GRANT USAGE ON SEQUENCE "notification"."notification_activity_id_seq" TO "social";
GRANT usage ON SCHEMA notification to social;
GRANT usage ON SCHEMA integration to social;
GRANT USAGE ON SEQUENCE "integration"."integration_id_seq" TO "social";
GRANT USAGE ON SEQUENCE "integration"."channel_integration_id_seq" TO "social";
GRANT USAGE ON SEQUENCE "integration"."integration_id_seq" TO "social";
GRANT USAGE ON SEQUENCE "integration"."channel_integration_id_seq" TO "social";
GRANT usage ON SCHEMA integration to social;

DO
$body$
BEGIN
   IF NOT EXISTS (
      SELECT *
      FROM   pg_catalog.pg_user
      WHERE  usename = 'socialapp201506') THEN

      CREATE USER socialapp201506 PASSWORD 'socialapp201506';
   END IF;
END
$body$
;
GRANT social TO socialapp201506;

DO
$body$
BEGIN
   IF NOT EXISTS (
      SELECT *
      FROM   pg_catalog.pg_user
      WHERE  usename = 'kontrolapp201506') THEN

      CREATE USER kontrolapp201506 PASSWORD 'kontrolapp201506';
   END IF;
END
$body$
;

DO
$body$
BEGIN
   IF NOT EXISTS (
      SELECT *
      FROM   pg_catalog.pg_roles
      WHERE  rolname = 'kontrol') THEN

      CREATE ROLE kontrol;
   END IF;
END
$body$
;

GRANT kontrol TO kontrolapp201506;


ALTER USER paymentro with password 'N8bG8ZVjp2y87Zxfi3';

-- create a schema for our tables
CREATE SCHEMA kite;

-- give usage access to schema for our role
GRANT USAGE ON SCHEMA kite TO kontrol;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

--
-- create key table for storing key pairs
--
CREATE TABLE IF NOT EXISTS "kite"."key" (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    public TEXT NOT NULL COLLATE "default", -- public will store public key of pair
    private TEXT NOT NULL COLLATE "default", -- private will store private key of pair
    created_at timestamp(6) WITH TIME ZONE NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    deleted_at timestamp(6) WITH TIME ZONE, -- update deleted at if a key pair become obsolote

    -- create constraints along with table creation
    PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE,
    CONSTRAINT "key_public_unique" UNIQUE ("public") NOT DEFERRABLE INITIALLY IMMEDIATE,
    CONSTRAINT "key_private_unique" UNIQUE ("private") NOT DEFERRABLE INITIALLY IMMEDIATE,
    CONSTRAINT "key_created_at_lte_deleted_at_check" CHECK (created_at <= deleted_at)
) WITH (OIDS = FALSE);

GRANT SELECT, INSERT, UPDATE ON "kite"."key" TO "kontrol"; -- dont allow deletion from this table

-- create the table
CREATE UNLOGGED TABLE "kite"."kite" (
    username TEXT NOT NULL,
    environment TEXT NOT NULL,
    kitename TEXT NOT NULL,
    version TEXT NOT NULL,
    region TEXT NOT NULL,
    hostname TEXT NOT NULL,
    id uuid PRIMARY KEY,
    url TEXT NOT NULL,
    created_at timestamptz NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'), -- you may set a global timezone
    updated_at timestamptz NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    key_id UUID NOT NULL,

    CONSTRAINT "kite_key_id_fkey" FOREIGN KEY ("key_id") REFERENCES kite.key (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE
);

-- add proper permissions for table
GRANT SELECT, INSERT, UPDATE, DELETE ON "kite"."kite" TO "kontrol";

-- create the index, but drop first if exists
DROP INDEX IF EXISTS kite_updated_at_btree_idx;

CREATE INDEX kite_updated_at_btree_idx ON "kite"."kite" USING BTREE (updated_at DESC);
