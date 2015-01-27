--
-- create the sequence
--
DO $$
  BEGIN
    BEGIN
      CREATE SEQUENCE "api"."channel_link_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
    EXCEPTION WHEN duplicate_table THEN
      RAISE NOTICE 'api.channel_link_id_seq sequence already exists';
    END;
  END;
$$;


-- grant the usage on sequence
GRANT USAGE ON SEQUENCE "api"."channel_link_id_seq" TO "social";

-----------------------------------------------------------------------

-- create channel_link table for storing the relation between root and leaf
-- channel
CREATE TABLE IF NOT EXISTS "api"."channel_link"  (
    "id" BIGINT NOT NULL DEFAULT nextval(
        'api.channel_link_id_seq' :: regclass
    ),
    "root_id" BIGINT NOT NULL,
    "leaf_id" BIGINT NOT NULL,
    "created_at" TIMESTAMP(6) WITH TIME ZONE NOT NULL,

    -- create constraints along with table creation
    PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE,
    CONSTRAINT "channel_link_root_id_fkey" FOREIGN KEY ("root_id") REFERENCES "api"."channel" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE,
    CONSTRAINT "channel_link_leaf_id_fkey" FOREIGN KEY ("leaf_id") REFERENCES "api"."channel" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE,
    CONSTRAINT "channel_link_root_id_leaf_id_key" UNIQUE ("root_id","leaf_id") NOT DEFERRABLE INITIALLY IMMEDIATE
) WITH (OIDS=FALSE);

-- give required channel_link permissions
GRANT SELECT, INSERT, DELETE ON "api"."channel_link" TO "social";
