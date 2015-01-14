DO $$
  BEGIN
    BEGIN
      ALTER TABLE api.account ADD COLUMN token UUID NOT NULL DEFAULT uuid_generate_v4();
    EXCEPTION
      WHEN duplicate_column THEN RAISE NOTICE 'column already exists';
    END;
  END;
$$;

DO $$
  BEGIN
    BEGIN
      ALTER TABLE api.account ADD CONSTRAINT "account_token_key" UNIQUE ("token") NOT DEFERRABLE INITIALLY IMMEDIATE;
    EXCEPTION
      WHEN duplicate_table THEN RAISE NOTICE 'constraint already exists';
    END;
  END;
$$;
