-- ----------------------------
--  Table structure for customer
-- ----------------------------
CREATE TYPE "payment"."provider_enum" AS ENUM (
    'stripe',
    'paypal'
);
ALTER TYPE "payment"."provider_enum" OWNER TO "social";

DROP TABLE IF EXISTS "payment"."customer";
CREATE TABLE "payment"."customer" (
    "id" BIGINT NOT NULL DEFAULT nextval(
        'payment.customer_id_seq' :: regclass
    ),
    "provider"             "payment"."provider_enum",
    "provider_customer_id" TEXT NOT NULL COLLATE "default",
    "old_id"               VARCHAR (24) NOT NULL COLLATE "default",

    "created_at" TIMESTAMP (6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "updated_at" TIMESTAMP (6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "deleted_at" TIMESTAMP (6) WITH TIME ZONE
) WITH (OIDS = FALSE);

GRANT SELECT, UPDATE, INSERT, DELETE ON "payment"."customer" TO "social";

-- ----------------------------
--  Table structure for plan
-- ----------------------------
CREATE TYPE "payment"."plan_interval_enum" AS ENUM (
    'month',
    'year'
);
ALTER TYPE "payment"."plan_interval_enum" OWNER TO "social";

CREATE TYPE "payment"."plan_title_enum" AS ENUM (
    'free',
    'hobbyist',
    'developer',
    'professional',
    'super',
    'bootstrap',
    'startup',
    'enterprise',
    'team_base',
    'team_free'
);
ALTER TYPE "payment"."plan_title_enum" OWNER TO "social";

DROP TABLE IF EXISTS "payment"."plan";
CREATE TABLE "payment"."plan" (
    "id" BIGINT NOT NULL DEFAULT nextval(
        'payment.plan_id_seq' :: regclass
    ),
    "interval"         "payment"."plan_interval_enum",
    "title"            "payment"."plan_title_enum",
    "provider"         "payment"."provider_enum",
    "provider_plan_id" TEXT NOT NULL COLLATE "default",
    "amount_in_cents"  BIGINT NOT NULL DEFAULT 0,

    "created_at" TIMESTAMP (6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "updated_at" TIMESTAMP (6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "deleted_at" TIMESTAMP (6) WITH TIME ZONE
) WITH (OIDS = FALSE);

GRANT SELECT, UPDATE, INSERT, DELETE ON "payment"."plan" TO "social";

-- ----------------------------
--  Table structure for subscription
-- ----------------------------
CREATE TYPE "payment"."subscription_state_enum" AS ENUM (
    'active',
    'expired',
    'canceled'
);
ALTER TYPE "payment"."subscription_state_enum" OWNER TO "social";

DROP TABLE IF EXISTS "payment"."subscription";
CREATE TABLE "payment"."subscription" (
    "id" BIGINT NOT NULL DEFAULT nextval(
        'payment.subscription_id_seq' :: regclass
    ),
    "state"                    "payment"."subscription_state_enum",
    "provider"                 "payment"."provider_enum",
    "provider_subscription_id" TEXT NOT NULL COLLATE "default",
    "provider_token"           TEXT NOT NULL COLLATE "default",
    "customer_id"              BIGINT NOT NULL DEFAULT 0,
    "plan_id"                  BIGINT NOT NULL DEFAULT 0,
    "amount_in_cents"          BIGINT NOT NULL DEFAULT 0,

    "created_at"            TIMESTAMP (6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "updated_at"            TIMESTAMP (6) WITH TIME ZONE NOT NULL DEFAULT now(),
    "expired_at"            TIMESTAMP (6) WITH TIME ZONE,
    "canceled_at"           TIMESTAMP (6) WITH TIME ZONE,
    "current_period_start"  TIMESTAMP (6) WITH TIME ZONE,
    "current_period_end"    TIMESTAMP (6) WITH TIME ZONE
) WITH (OIDS = FALSE);

GRANT SELECT, UPDATE, INSERT, DELETE ON "payment"."subscription" TO "social";
