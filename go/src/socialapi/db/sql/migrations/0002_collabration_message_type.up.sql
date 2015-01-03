-- add new type into the channel types
-- ALTER TYPE "api"."channel_type_constant_enum" ADD VALUE IF NOT EXISTS 'collaboration';

-- add new coloumn into channel
ALTER TABLE "api"."channel" ADD COLUMN "payload" hstore;
