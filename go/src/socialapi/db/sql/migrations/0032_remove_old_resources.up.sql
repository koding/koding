DO $$
BEGIN
    IF EXISTS(
        SELECT schema_name
          FROM information_schema.schemata
          WHERE schema_name = 'integration'
      )
    THEN
        -- if schema does not exist, drop statements will fail.
        DROP TABLE      IF EXISTS "integration"."channel_integration";
        DROP TABLE      IF EXISTS "integration"."integration";
        DROP INDEX      IF EXISTS "integration"."channel_integration_pkey";
        DROP INDEX      IF EXISTS "integration"."channel_integration_token_idx";
        DROP INDEX      IF EXISTS "integration"."channel_integration_token_key";
        DROP INDEX      IF EXISTS "integration"."integration_name";
        DROP INDEX      IF EXISTS "integration"."integration_pkey";
        DROP SEQUENCE   IF EXISTS "integration"."channel_integration_id_seq";
        DROP SEQUENCE   IF EXISTS "integration"."integration_id_seq";
        DROP TYPE       IF EXISTS "integration"."integration_type_constant_enum";
        DROP SCHEMA     IF EXISTS integration;
    END IF;
END
$$;

DO $$
BEGIN
    IF EXISTS(
        SELECT schema_name
          FROM information_schema.schemata
          WHERE schema_name = 'notification'
      )
    THEN
        DROP INDEX      IF EXISTS "notification"."notification_content_type_constant_target_id_idx";
        DROP INDEX      IF EXISTS "notification"."notification_account_id_context_id_notification_content_id_idx";
        DROP INDEX      IF EXISTS "notification"."notification_activity_actor_id_content_id_obsolete_idx";
        DROP TABLE      IF EXISTS "notification"."notification_setting";
        DROP TABLE      IF EXISTS "notification"."notification";
        DROP TABLE      IF EXISTS "notification"."notification_activity";
        DROP TABLE      IF EXISTS "notification"."notification_content";
        DROP SEQUENCE   IF EXISTS "notification"."notification_activity_id_seq";
        DROP SEQUENCE   IF EXISTS "notification"."notification_content_id_seq";
        DROP SEQUENCE   IF EXISTS "notification"."notification_id_seq";
        DROP SEQUENCE   IF EXISTS "notification"."notification_setting_id_seq";
        DROP TYPE       IF EXISTS "notification"."notification_content_type_constant_enum";
        DROP TYPE       IF EXISTS "notification"."notification_setting_status_constant_enum";
        DROP SCHEMA     IF EXISTS notification;
    END IF;
END
$$;


DO $$
BEGIN
    IF EXISTS(
        SELECT schema_name
          FROM information_schema.schemata
          WHERE schema_name = 'payment'
      )
    THEN
        DROP INDEX      IF EXISTS "payment"."customer_old_id_idx";
        DROP INDEX      IF EXISTS "payment"."payment_customer_lookup_idx";
        DROP TABLE      IF EXISTS "payment"."subscription";
        DROP TABLE      IF EXISTS "payment"."customer";
        DROP TABLE      IF EXISTS "payment"."plan";
        DROP SEQUENCE   IF EXISTS "payment"."customer_id_seq";
        DROP SEQUENCE   IF EXISTS "payment"."plan_id_seq";
        DROP SEQUENCE   IF EXISTS "payment"."subscription_id_seq";
        DROP TYPE       IF EXISTS "payment"."customer_type_constant_enum";
        DROP TYPE       IF EXISTS "payment"."plan_interval_enum";
        DROP TYPE       IF EXISTS "payment"."plan_title_enum";
        DROP TYPE       IF EXISTS "payment"."plan_type_constant_enum";
        DROP TYPE       IF EXISTS "payment"."provider_enum";
        DROP TYPE       IF EXISTS "payment"."subscription_state_enum";
        DROP SCHEMA     IF EXISTS payment;
    END IF;
END
$$;

DO $$
BEGIN
    IF EXISTS(
        SELECT schema_name
          FROM information_schema.schemata
          WHERE schema_name = 'sitemap'
      )
    THEN
        DROP TABLE      IF EXISTS "sitemap"."file";
        DROP INDEX      IF EXISTS "sitemap"."file_name_key";
        DROP INDEX      IF EXISTS "sitemap"."file_pkey";
        DROP SEQUENCE   IF EXISTS "sitemap"."file_id_seq";
        DROP SCHEMA     IF EXISTS sitemap;
    END IF;
END
$$;
