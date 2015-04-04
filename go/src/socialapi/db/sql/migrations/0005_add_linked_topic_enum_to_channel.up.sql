--
-- We need "linkedtopic" enum for keeping the state of the channel in the
-- channel table, linked channels should not be listed in search etc
--
-- ALTER TYPE "api"."channel_type_constant_enum" ADD VALUE IF NOT EXISTS 'linkedtopic';
-- this is just a stub
Select 1 from pg_tables;
