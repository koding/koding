--CREATE TYPE "payment"."customer_type_enum" AS ENUM (
--  'group',
--  'account'
--);
--ALTER TYPE "payment"."customer_type_enum" OWNER TO "social";
--ALTER TABLE payment.customer ADD COLUMN "type" "payment"."customer_type_enum";

--CREATE TYPE "payment"."plan_type_enum" AS ENUM (
--  'group',
--  'account'
--);
--ALTER TYPE "payment"."plan_type_enum" OWNER TO "social";
--ALTER TABLE payment.plan ADD COLUMN "type" "payment"."plan_type_enum";

--ALTER TYPE "payment"."plan_title_enum" ADD VALUE IF NOT EXISTS 'bootstrap' AFTER 'super';
--ALTER TYPE "payment"."plan_title_enum" ADD VALUE IF NOT EXISTS 'startup' AFTER 'bootstrap';
--ALTER TYPE "payment"."plan_title_enum" ADD VALUE IF NOT EXISTS 'enterprise' AFTER 'startup';

--INSERT INTO "payment"."plan" (interval, title, provider, provider_plan_id, amount_in_cents, type)
--  VALUES ('month', 'bootstrap', 'stripe', 'bootstrap_month', 300, 'group')
--  , ('month', 'startup', 'stripe', 'startup_month', 3000, 'group')
--  , ('month', 'enterprise', 'stripe', 'enterprise_month', 10000, 'group')
--;

--UPDATE plan SET type='account' WHERE type IS NULL;
--UPDATE customer SET type='account' WHERE type IS NULL;
