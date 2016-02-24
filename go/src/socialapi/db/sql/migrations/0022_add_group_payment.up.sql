-- add enum for customer
DO $$
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'customer_type_enum') THEN
      CREATE TYPE "payment"."customer_type_enum" AS ENUM (
        'group',
        'account'
      );

      ALTER TYPE "payment"."customer_type_enum" OWNER TO "social";
    END IF;
  END;
$$;

-- add enum for plan
DO $$
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'plan_type_enum') THEN
      CREATE TYPE "payment"."plan_type_enum" AS ENUM (
        'group',
        'account'
      );

      ALTER TYPE "payment"."plan_type_enum" OWNER TO "social";
    END IF;
  END;
$$;

-- add 'type' to customer
DO $$
  BEGIN
    BEGIN
      ALTER TABLE payment.customer ADD COLUMN "type" "payment"."customer_type_enum";
      EXCEPTION
      WHEN duplicate_column THEN RAISE NOTICE 'column already exists';
    END;
  END;
$$;

-- add 'type' to plan
DO $$
  BEGIN
    BEGIN
      ALTER TABLE payment.plan ADD COLUMN "type" "payment"."plan_type_enum";
      EXCEPTION
      WHEN duplicate_column THEN RAISE NOTICE 'column already exists';
    END;
  END;
$$;

-- create index
DO $$
  BEGIN
    CREATE INDEX  "payemnt_customer_lookup_idx" ON payment.customer USING btree(type DESC NULLS LAST, old_id DESC NULLS LAST);
    EXCEPTION WHEN duplicate_table THEN
      RAISE NOTICE 'payemnt_customer_lookup_idx already exists';
  END;
$$;
