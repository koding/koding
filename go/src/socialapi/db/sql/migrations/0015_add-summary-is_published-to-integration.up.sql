--
--
--
--
--
--

DO $$
  BEGIN
    BEGIN
      ALTER TABLE integration.integration ADD COLUMN summary TEXT COLLATE "default";
    EXCEPTION
      WHEN duplicate_column THEN RAISE NOTICE 'column already exists';
    END;
    BEGIN
      ALTER TABLE integration.integration ADD COLUMN is_published BOOLEAN NOT NULL DEFAULT FALSE;
    EXCEPTION
      WHEN duplicate_column THEN RAISE NOTICE 'column already exists';
    END;
  END;
$$;
