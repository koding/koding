-- Clean up for database.sql
--
-- Drop database
DROP DATABASE IF EXISTS social;

-- Drop role
-- DROP OWNED BY social CASCADE;
DROP ROLE IF EXISTS social;

-- Drop user
-- DROP OWNED BY socialapplication CASCADE;
DROP USER IF EXISTS socialapplication;
DROP USER IF EXISTS socialapp201506;
DROP USER IF EXISTS socialapp_2016_05;

-- Drop tablespaces
-- we dont need tablespaces anymore...
-- Amazon RDS supports tablespaces since they are writing to same volume
-- it is not necessary
--DROP TABLESPACE IF EXISTS social;
--DROP TABLESPACE IF EXISTS socialbig;


