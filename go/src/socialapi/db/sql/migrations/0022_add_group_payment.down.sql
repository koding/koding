DROP INDEX IF EXISTS "payment"."payment_customer_lookup_idx";

-- drop column before enum
ALTER TABLE payment.customer DROP COLUMN type_constant;
ALTER TABLE payment.plan DROP COLUMN type_constant;

DROP TYPE IF EXISTS "payment"."customer_type_constant_enum";
DROP TYPE IF EXISTS "payment"."plan_type_constant_enum";
