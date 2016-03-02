-- this is commented out since migrate package errors on `ALTER TYPE`
--
--ALTER TYPE "payment"."plan_title_enum" ADD VALUE IF NOT EXISTS 'bootstrap' AFTER 'super';
--ALTER TYPE "payment"."plan_title_enum" ADD VALUE IF NOT EXISTS 'startup' AFTER 'bootstrap';
--ALTER TYPE "payment"."plan_title_enum" ADD VALUE IF NOT EXISTS 'enterprise' AFTER 'startup';

DO $$
  BEGIN
    BEGIN
      INSERT INTO "payment"."plan" (interval, title, provider, provider_plan_id, amount_in_cents, type_constant)
       VALUES ('month', 'bootstrap', 'stripe', 'bootstrap_month', 300, 'group')
       , ('month', 'startup', 'stripe', 'startup_month', 3000, 'group')
       , ('month', 'enterprise', 'stripe', 'enterprise_month', 10000, 'group')
      ;
      EXCEPTION
      WHEN unique_violation THEN RAISE NOTICE 'item already exists';
    END;
  END;
$$;

UPDATE "payment"."plan" SET type_constant='account' WHERE type_constant IS NULL;
UPDATE "payment"."customer" SET type_constant='account' WHERE type_constant IS NULL;
