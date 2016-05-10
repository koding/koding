-- this is commented out since migrate package errors on `ALTER TYPE`
--
--ALTER TYPE "payment"."plan_title_enum" ADD VALUE IF NOT EXISTS 'team_base';

DO $$
  BEGIN
    BEGIN
      INSERT INTO "payment"."plan" (interval, title, provider, provider_plan_id, amount_in_cents, type_constant)
       VALUES ('month', 'team_base', 'stripe', 'team_base_month', 0, 'group')
      ;
      EXCEPTION
      WHEN unique_violation THEN RAISE NOTICE 'item already exists';
    END;
  END;
$$;

UPDATE "payment"."plan" SET type_constant='account' WHERE type_constant IS NULL;
UPDATE "payment"."customer" SET type_constant='account' WHERE type_constant IS NULL;
