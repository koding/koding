-- SET ROLE social;

CREATE SCHEMA notification;

GRANT usage ON SCHEMA notification to socialapplication;

-- append notification schema
SELECT set_config('search_path', current_setting('search_path') || ',notification', false);
