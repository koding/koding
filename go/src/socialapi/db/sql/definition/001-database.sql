-- Run this part in postgres database
CREATE ROLE social;

CREATE USER socialapplication PASSWORD 'socialapplication';

GRANT social TO socialapplication WITH ADMIN OPTION;
--GRANT social_superuser TO social WITH ADMIN OPTION;

-- After Amazon RDS, we dont need tablespaces
-- But here for future referance
-- CREATE TABLESPACE social LOCATION '/data/postgresql/tablespace/social';
-- CREATE TABLESPACE socialbig LOCATION '/data/postgresql/tablespace/socialbig';
-- GRANT CREATE ON TABLESPACE socialbig TO social;

-- While creating the instance from the RDS UI we are creating the social database
-- ALTER DATABASE social OWNER TO social;

-- CREATE DATABASE social OWNER social ENCODING 'UTF8'  TEMPLATE template0;
-- In any need for a custom schema
-- CREATE DATABASE social OWNER social ENCODING 'UTF8' TABLESPACE social;
