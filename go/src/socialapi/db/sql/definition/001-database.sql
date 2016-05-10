-- Run this part in postgres database
CREATE ROLE social;

-- old socialapplication user
CREATE USER socialapplication PASSWORD 'socialapplication';

-- new socialapp user
CREATE USER socialapp201506 PASSWORD 'socialapp201506'; -- password is just for reference
CREATE USER socialapp_2016_05 PASSWORD 'socialapp_2016_05'; -- password is just for reference

-- social superuser
CREATE USER social_superuser PASSWORD 'social_superuser';

-- grant access to social role for all users
GRANT social TO socialapplication;
GRANT social TO socialapp201506;
GRANT social TO socialapp_2016_05;

ALTER USER social_superuser WITH SUPERUSER;

-- After Amazon RDS, we dont need tablespaces
-- But here for future referance
-- CREATE TABLESPACE social LOCATION '/data/postgresql/tablespace/social';
-- CREATE TABLESPACE socialbig LOCATION '/data/postgresql/tablespace/socialbig';
-- GRANT CREATE ON TABLESPACE socialbig TO social;

-- While creating the instance from the RDS UI we are creating the social database
-- ALTER DATABASE social OWNER TO social;

-- remove this line for RDS creation
CREATE DATABASE social OWNER social ENCODING 'UTF8'  TEMPLATE template0;
-- In any need for a custom schema
-- CREATE DATABASE social OWNER social ENCODING 'UTF8' TABLESPACE social;
