-- we are adding delete permission while implementing channel moderation after
-- merging 2 channels, we need to remove or update the participant of the leaf
-- node
--
-- delete requires select
GRANT SELECT, DELETE ON "api"."channel_participant" TO "social";
