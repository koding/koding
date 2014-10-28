ALTER TYPE "payment"."plan_title_enum" ADD VALUE 'betatester' AFTER 'koding';

INSERT INTO "payment"."plan" (interval, title, provider, provider_plan_id, amount_in_cents)
  VALUES ('month', 'betatester', 'koding', '2', 0);
