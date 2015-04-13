DO $$
  BEGIN
    BEGIN
      ALTER TABLE api.account ADD COLUMN "settings" hstore;
    EXCEPTION
      WHEN duplicate_column THEN RAISE NOTICE 'column already exists';
    END;
  END;
$$;
