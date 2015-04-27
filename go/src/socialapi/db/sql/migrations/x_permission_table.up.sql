
-- ----------------------------
--  Sequence structure for permission_id_seq
-- ----------------------------
--

--
-- create the sequence
--
DO $$
  BEGIN
    BEGIN
      CREATE SEQUENCE "api"."permission_id_seq" INCREMENT 1 START 1 MAXVALUE 9223372036854775807 MINVALUE 1 CACHE 1;
    EXCEPTION WHEN duplicate_table THEN
      RAISE NOTICE 'api.permission_id_seq sequence already exists';
    END;
  END;
$$;


-- grant the usage on sequence
GRANT USAGE ON SEQUENCE "api"."permission_id_seq" TO "social";

-----------------------------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------

-- Create "api"."role_constant_enum"
--
-- All of this to create a type if it does not exist
CREATE OR REPLACE FUNCTION create_api_role_constant_enum_type() RETURNS integer AS $$
DECLARE v_exists INTEGER;

BEGIN
    SELECT into v_exists (SELECT 1 FROM pg_type WHERE typname = 'role_constant_enum');
    IF v_exists IS NULL THEN

        CREATE TYPE "api"."role_constant_enum" AS ENUM (
            'admin',
            'moderator',
            'member',
            'guest'
        );
    END IF;
    RETURN v_exists;
END;
$$ LANGUAGE plpgsql;

-- Call the function
SELECT create_api_role_constant_enum_type();
-- Remove the function
DROP function create_api_role_constant_enum_type();


-----------------------------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------


-- Create "api"."role_constant_enum"
--
-- All of this to create a type if it does not exist
CREATE OR REPLACE FUNCTION create_api_permission_status_constant_enum_type() RETURNS integer AS $$
DECLARE v_exists INTEGER;

BEGIN
    SELECT into v_exists (SELECT 1 FROM pg_type WHERE typname = 'permission_status_constant_enum');
    IF v_exists IS NULL THEN

        CREATE TYPE "api"."permission_status_constant_enum" AS ENUM (
            'allowed',
            'disallowed'
        );

    END IF;
    RETURN v_exists;
END;
$$ LANGUAGE plpgsql;

-- Call the function
SELECT create_api_permission_status_constant_enum_type();
-- Remove the function
DROP function create_api_permission_status_constant_enum_type();

-----------------------------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS "api"."permission"  (
    "id" BIGINT NOT NULL DEFAULT nextval(
        'api.permission_id_seq' :: regclass
    ),
    "name" VARCHAR(200) NOT NULL COLLATE "default",
    "channel_id" BIGINT NOT NULL,
    "role_constant" "api"."role_constant_enum",
    "status_constant" "api"."permission_status_constant_enum",
    "created_at" TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    "updated_at" TIMESTAMP(6) WITH TIME ZONE NOT NULL,

    -- create constraints along with table creation
    PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE,
    CONSTRAINT "permission_name_channel_id_role_constant_key" UNIQUE ("name","channel_id","role_constant") NOT DEFERRABLE INITIALLY IMMEDIATE,
    CONSTRAINT "permission_channel_id_fkey" FOREIGN KEY ("channel_id") REFERENCES "api"."channel" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION NOT DEFERRABLE INITIALLY IMMEDIATE
) WITH (OIDS=FALSE);

-- give required permission
GRANT SELECT, INSERT, UPDATE ON "api"."permission" TO "social";


-------------
-- channel participant table
-------------
-- add new coloumn into channel participant table
DO $$
  BEGIN
    BEGIN
      ALTER TABLE "api"."channel_participant" ADD COLUMN "role_constant" "api"."role_constant_enum" DEFAULT 'member';
    EXCEPTION
      WHEN duplicate_column THEN RAISE NOTICE 'column already exists';
    END;
  END;
$$;
