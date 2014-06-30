CREATE ROLE social;

CREATE USER socialapplication PASSWORD 'socialapplication';

GRANT social TO socialapplication WITH ADMIN OPTION;

--CREATE TABLESPACE social LOCATION '/var/lib/postgresql/data/tablespace/social';

--CREATE TABLESPACE socialbig LOCATION '/var/lib/postgresql/data/tablespace/socialbig';

--GRANT create ON TABLESPACE socialbig to social;

--CREATE DATABASE social  OWNER social ENCODING 'UTF8' TABLESPACE social;
CREATE DATABASE social  OWNER social ENCODING 'UTF8';

