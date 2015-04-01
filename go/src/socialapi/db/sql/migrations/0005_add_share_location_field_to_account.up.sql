DO $$
  BEGIN
    BEGIN
      ALTER TABLE api.account ADD COLUMN "share_location" BOOLEAN NOT NULL DEFAULT FALSE;
    EXCEPTION
      WHEN duplicate_column THEN RAISE NOTICE 'column already exists';
    END;
  END;
$$;
