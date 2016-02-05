CREATE TYPE "payment"."customer_type_enum" AS ENUM (
    'group',
    'account'
);
ALTER TYPE "payment"."customer_type_enum" OWNER TO "social";

ALTER TABLE payment.customer ADD COLUMN "type" "payment"."customer_type_enum";
