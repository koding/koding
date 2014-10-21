ALTER TYPE "payment"."provider_enum" ADD VALUE 'koding' AFTER 'paypal';
ALTER TYPE "payment"."plan_title_enum" ADD VALUE 'koding' AFTER 'super';

INSERT INTO "payment"."plan" (interval, title, provider, provider_plan_id, amount_in_cents)
  VALUES ('month', 'koding', 'koding', '1', 0);
