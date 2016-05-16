-- this is commented out since migrate package errors on `ALTER TYPE`
--
--ALTER TYPE "payment"."plan_title_enum" ADD VALUE IF NOT EXISTS 'team_free';

DO $$
  BEGIN
    BEGIN
      INSERT INTO "payment"."plan" (interval, title, provider, provider_plan_id, amount_in_cents, type_constant)
       VALUES ('month', 'team_free', 'stripe', 'team_free_month', 0, 'group')
      ;
      EXCEPTION
      WHEN unique_violation THEN RAISE NOTICE 'item already exists';
    END;
  END;
$$;
