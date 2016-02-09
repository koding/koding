ALTER TYPE "payment"."plan_title_enum" ADD VALUE IF NOT EXISTS 'bootstrap' AFTER 'super';
ALTER TYPE "payment"."plan_title_enum" ADD VALUE IF NOT EXISTS 'startup' AFTER 'bootstrap';
ALTER TYPE "payment"."plan_title_enum" ADD VALUE IF NOT EXISTS 'enterprise' AFTER 'startup';

INSERT INTO "payment"."plan" (interval, title, provider, provider_plan_id, amount_in_cents, 'type')
  VALUES ('month', 'bootstrap', 'stripe', 'bootstrap_month', 300, 'group')
  , ('month', 'startup', 'stripe', 'startup_month', 3000, 'group')
  , ('month', 'enterprise', 'stripe', 'enterprise_month', 10000, 'group')
  ;
