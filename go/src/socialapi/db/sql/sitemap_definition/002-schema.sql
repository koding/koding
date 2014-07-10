SET ROLE social;

CREATE SCHEMA sitemap;

GRANT usage ON SCHEMA sitemap to socialapplication;

-- append sitemap schema
SELECT set_config('search_path', current_setting('search_path') || ',sitemap', false);