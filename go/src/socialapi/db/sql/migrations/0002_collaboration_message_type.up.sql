-- add new type into the channel types
-- ALTER TYPE "api"."channel_type_constant_enum" ADD VALUE IF NOT EXISTS 'collaboration';

-- add new coloumn into channel
DO $$
  BEGIN
    BEGIN
      ALTER TABLE "api"."channel" ADD COLUMN "payload" hstore;
    EXCEPTION
      WHEN duplicate_column THEN RAISE NOTICE 'column already exists';
    END;
  END;
$$;
