SET ROLE social;

CREATE SCHEMA api;

-- since extension creation is handled in current database,
-- hstore is created here
SET ROLE postgres;
CREATE EXTENSION IF NOT EXISTS hstore;
SET ROLE social;

GRANT USAGE ON SCHEMA api TO socialapplication;

ALTER DATABASE social SET search_path="$user", public, api;
