--
-- We need "activity" type constant for channel message table, for storing user
-- activities
--
-- ALTER TYPE "api"."channel_message_type_constant_enum" ADD VALUE IF NOT EXISTS 'activity';
-- this is just a stub
Select 1 from pg_tables;
