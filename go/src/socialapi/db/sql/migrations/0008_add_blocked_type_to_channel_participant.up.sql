--
-- We need "blocked" enum for keeping the blocked state of the channel participant
--
-- ALTER TYPE "api"."channel_participant_status_constant_enum" ADD VALUE IF NOT EXISTS 'blocked';
--
-- this is just a stub
Select 1 from pg_tables;
