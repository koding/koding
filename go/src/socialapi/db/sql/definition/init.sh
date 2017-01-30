mkdir -p /data/postgresql/tablespace/social
mkdir -p /data/postgresql/tablespace/socialbig

chown -R postgres:postgres /data/postgresql/tablespace

su postgres -c "dropdb postgres"
su postgres -c "createdb postgres"
