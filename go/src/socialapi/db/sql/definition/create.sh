# create folders for postgres data
sudo mkdir -p /data/postgresql/tablespace/social
sudo mkdir -p /data/postgresql/tablespace/socialbig
# give ownership to postgres
sudo chown -R postgres:postgres /data/postgresql/tablespace

sudo -u postgres dropdb postgres
sudo -u postgres createdb postgres

# create initial database
sudo -u postgres psql postgres < /opt/koding/go/src/socialapi/db/sql/definition/001-database.sql

# create  schema definitions
sudo -u postgres psql social < /opt/koding/go/src/socialapi/db/sql/definition/002-schema.sql

# create sequences
sudo -u postgres psql social < /opt/koding/go/src/socialapi/db/sql/definition/003-sequence.sql

# create sequence functions
sudo -u postgres psql social < /opt/koding/go/src/socialapi/db/sql/definition/003-sequencefunction.sql

# create tables
sudo -u postgres psql social < /opt/koding/go/src/socialapi/db/sql/definition/004-table.sql

# ctreate constraints
sudo -u postgres psql social < /opt/koding/go/src/socialapi/db/sql/definition/005-constraint.sql

/opt/koding/go/src/socialapi/workers/notification/sql/create.sh
