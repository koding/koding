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

-- add key_id column into kite table
DO $$
  BEGIN
    BEGIN
      ALTER TABLE kite.kite ADD COLUMN "key_id" UUID NOT NULL;
    EXCEPTION
      WHEN duplicate_column THEN RAISE NOTICE 'key_id column already exists';
    END;
  END;
$$;

-- create foreign constraint between kite.kite.key_id and kite.key.id
DO $$
  BEGIN
    BEGIN
      ALTER TABLE kite.kite ADD CONSTRAINT "kite_key_id_fkey" FOREIGN KEY ("key_id") REFERENCES kite.key (id) ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE;
    EXCEPTION
      WHEN duplicate_object THEN RAISE NOTICE 'kite_key_id_fkey already exists';
    END;
  END;
$$;

