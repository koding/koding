-- Drop database
DROP DATABASE IF EXISTS social;

-- Drop role
-- DROP OWNED BY social CASCADE;
DROP ROLE IF EXISTS social;

-- Drop user
-- DROP OWNED BY socialapplication CASCADE;
DROP USER IF EXISTS socialapplication;

-- Drop tablespaces
DROP TABLESPACE IF EXISTS social;
DROP TABLESPACE IF EXISTS socialbig;


CREATE ROLE social;

CREATE USER socialapplication PASSWORD 'socialapplication';

GRANT social TO socialapplication WITH ADMIN OPTION;

CREATE TABLESPACE social LOCATION '/data/postgresql/tablespace/social';

CREATE TABLESPACE socialbig LOCATION '/data/postgresql/tablespace/socialbig';

GRANT CREATE ON TABLESPACE socialbig TO social;

CREATE DATABASE social OWNER social ENCODING 'UTF8' TABLESPACE social;

