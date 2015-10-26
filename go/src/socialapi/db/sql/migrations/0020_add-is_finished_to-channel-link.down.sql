--
-- drop is_finished column
ALTER TABLE "api"."channel_link" DROP COLUMN "is_finished";

-- update channel_link permission
REVOKE UPDATE ON "api"."channel_link" FROM "social";