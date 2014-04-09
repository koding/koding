SET ROLE social;

CREATE SCHEMA api;

GRANT usage ON SCHEMA api to socialapplication;

ALTER DATABASE social set search_path="$user", public, api
