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

DO $$
  BEGIN
    BEGIN
      ALTER TABLE payment.customer ADD COLUMN "type" "payment"."customer_type_enum";
      EXCEPTION
      WHEN duplicate_column THEN RAISE NOTICE 'column already exists';
    END;
  END;
$$;

DO $$
  BEGIN
    BEGIN
      ALTER TABLE payment.plan ADD COLUMN "type" "payment"."plan_type_enum";
      EXCEPTION
      WHEN duplicate_column THEN RAISE NOTICE 'column already exists';
    END;
  END;
$$;
