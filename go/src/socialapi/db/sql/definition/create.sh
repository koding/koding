# create folders for postgres data
sudo mkdir -p /data/postgresql/tablespace/social
sudo mkdir -p /data/postgresql/tablespace/socialbig
# give ownership to postgres
sudo chown -R postgres:postgres /data/postgresql/tablespace


sudo -u postgres dropdb postgres
sudo -u postgres createdb postgres

# add UTF-8 support
sudo -u postgres psql postgres < $1/definition/000-UTF8.sql

# create initial database
sudo -u postgres psql postgres < $1/definition/001-database.sql

# create  schema definitions
sudo -u postgres psql social < $1/definition/002-schema.sql

# create sequences
sudo -u postgres psql social < $1/definition/003-sequence.sql

# create sequence functions
sudo -u postgres psql social < $1/definition/003-sequencefunction.sql

# create tables
sudo -u postgres psql social < $1/definition/004-table.sql

# ctreate constraints
sudo -u postgres  psql social < $1/definition/005-constraint.sql

# NOTIFICATION WORKER SQL IMPORTS

# create sequences
sudo -u postgres psql social < $1/notification_definition/002-schema.sql

# create sequences
sudo -u postgres psql social < $1/notification_definition/003-sequence.sql

# create tables
sudo -u postgres psql social < $1/notification_definition/004-table.sql

# create constraints
sudo -u postgres psql social < $1/notification_definition/005-constraint.sql
