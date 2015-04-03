-- With Team Product we need to have seperate notifications for each group.
-- For this reason we have added context_channel_id column
DO $$
  BEGIN
    BEGIN
      ALTER TABLE notification.notification ADD COLUMN context_channel_id BIGINT NOT NULL;
    EXCEPTION
      WHEN duplicate_column THEN RAISE NOTICE 'column already exists';
    END;
  END;
$$;
