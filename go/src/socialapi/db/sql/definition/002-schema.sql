-- This should be run in social db
-- set roles are not working in RDS
-- SET ROLE social;

CREATE SCHEMA api;

-- since extension creation is handled in current database,
-- hstore is created here
CREATE EXTENSION IF NOT EXISTS hstore;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

GRANT USAGE ON SCHEMA api TO social;

ALTER DATABASE social SET search_path="$user", public, api;

