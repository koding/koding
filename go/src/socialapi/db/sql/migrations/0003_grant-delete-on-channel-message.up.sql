--
-- We gave this permission to be able to remove unnecessary messages from db,
-- after everyone leaves a private message we are deleting every message and the
-- channel itself
--
GRANT DELETE ON "api"."channel_message" TO "social";

