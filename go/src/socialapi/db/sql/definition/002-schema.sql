SET ROLE social;

CREATE SCHEMA api;

SET ROLE postgres;
CREATE EXTENSION hstore SCHEMA api;
SET ROLE social;

GRANT usage ON SCHEMA api to socialapplication;

ALTER DATABASE social set search_path="$user", public, api;
