GRANT SELECT, INSERT, UPDATE, DELETE ON "sitemap"."file" TO "social";
GRANT USAGE ON SEQUENCE "sitemap"."file_id_seq" TO "social";
GRANT usage ON SCHEMA sitemap to social;
GRANT usage ON SCHEMA payment to social;
GRANT SELECT, INSERT, UPDATE ON "notification"."notification" TO "social";
GRANT SELECT, INSERT ON "notification"."notification_content" TO "social";
GRANT SELECT, INSERT, UPDATE ON "notification"."notification_activity" TO "social";
GRANT USAGE ON SEQUENCE "notification"."notification_id_seq" TO "social";
GRANT USAGE ON SEQUENCE "notification"."notification_content_id_seq" TO "social";
GRANT USAGE ON SEQUENCE "notification"."notification_activity_id_seq" TO "social";
GRANT usage ON SCHEMA notification to social;
GRANT usage ON SCHEMA integration to social;
GRANT USAGE ON SEQUENCE "integration"."integration_id_seq" TO "social";
GRANT USAGE ON SEQUENCE "integration"."channel_integration_id_seq" TO "social";
GRANT USAGE ON SEQUENCE "integration"."integration_id_seq" TO "social";
GRANT USAGE ON SEQUENCE "integration"."channel_integration_id_seq" TO "social";
GRANT usage ON SCHEMA integration to social;

DO
$body$
BEGIN
   IF NOT EXISTS (
      SELECT *
      FROM   pg_catalog.pg_user
      WHERE  usename = 'socialapp201506') THEN

      CREATE USER socialapp201506 PASSWORD 'socialapp201506';
   END IF;
END
$body$
;
GRANT social TO socialapp201506;

DO
$body$
BEGIN
   IF NOT EXISTS (
      SELECT *
      FROM   pg_catalog.pg_user
      WHERE  usename = 'kontrolapp201506') THEN

      CREATE USER kontrolapp201506 PASSWORD 'kontrolapp201506';
   END IF;
END
$body$
;

DO
$body$
BEGIN
   IF NOT EXISTS (
      SELECT *
      FROM   pg_catalog.pg_roles
      WHERE  rolname = 'kontrol') THEN

      CREATE ROLE kontrol;
   END IF;
END
$body$
;

GRANT kontrol TO kontrolapp201506;

ALTER USER paymentro with password 'N8bG8ZVjp2y87Zxfi3';
