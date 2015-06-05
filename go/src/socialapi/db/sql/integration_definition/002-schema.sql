-- SET ROLE social;

CREATE SCHEMA integration;

GRANT usage ON SCHEMA integration to social;

-- append sitemap schema
SELECT set_config('search_path', current_setting('search_path') || ',integration', false);
