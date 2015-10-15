--
-- Add is_finished column in channel_link
DO $$
  BEGIN
    BEGIN
	  ALTER TABLE "api"."channel_link" ADD COLUMN "is_finished" BOOLEAN NOT NULL DEFAULT FALSE;
    EXCEPTION
      WHEN duplicate_column THEN RAISE NOTICE 'column already exists';
    END;
  END;
$$;


-- give requeired update permission to channel_link
GRANT UPDATE ON "api"."channel_link" TO "social";