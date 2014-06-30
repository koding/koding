SET ROLE social;

CREATE SCHEMA api;

-- since extension creation is handled in current database,
-- hstore is created here
SET ROLE postgres;
CREATE EXTENSION IF NOT EXISTS hstore;
SET ROLE social;

GRANT usage ON SCHEMA api to socialapplication;

ALTER DATABASE social set search_path="$user", public, api;
