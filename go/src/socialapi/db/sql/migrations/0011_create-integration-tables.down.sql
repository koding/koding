
DROP TABLE "integration"."channel_integration";
DROP TABLE "integration"."integration";
DROP SEQUENCE "integration"."channel_integration_id_seq";
DROP SEQUENCE "integration"."integration_id_seq";
DROP TYPE "integration"."integration_type_constant_enum";

--
-- drop schema
--

DO $$
  BEGIN
    BEGIN
      DROP SCHEMA integration;
    END;
  END;
$$;

