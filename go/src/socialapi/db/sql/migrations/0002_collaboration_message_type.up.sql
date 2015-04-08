--
-- We need collabration type for stating the regarding channel belongs to a
-- collabration session, all the messages in that channel treated as private
-- messages but the channel itself is not listed in the sidebar along with
-- private message channels
--

-- add new type into the channel types

-- comment out for now, because our migration tool doesnt support non-transactional operation
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
