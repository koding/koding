# create folders for postgres data
sudo mkdir -p /data/postgresql/tablespace/social
sudo mkdir -p /data/postgresql/tablespace/socialbig
# give ownership to postgres
sudo chown -R postgres:postgres /data/postgresql/tablespace


sudo -u postgres dropdb postgres
sudo -u postgres createdb postgres

# clear database
sudo -u postgres psql postgres < $1/definition/000-cleanup.sql

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

# create kontrol specific tables
if [ -d "kontrol" ]; then
  sudo -u postgres psql social < $1/kontrol/001-schema.sql
  sudo -u postgres psql social < $1/kontrol/002-table.sql
fi

# NOTIFICATION WORKER SQL IMPORTS

# create sequences
sudo -u postgres psql social < $1/notification_definition/002-schema.sql

# create sequences
sudo -u postgres psql social < $1/notification_definition/003-sequence.sql

# create tables
sudo -u postgres psql social < $1/notification_definition/004-table.sql

# create constraints
sudo -u postgres psql social < $1/notification_definition/005-constraint.sql

# SITEMAP WORKER SQL IMPORTS

# create sequences
sudo -u postgres psql social < $1/sitemap_definition/002-schema.sql

# create sequences
sudo -u postgres psql social < $1/sitemap_definition/003-sequence.sql

# create tables
sudo -u postgres psql social < $1/sitemap_definition/004-table.sql

# create constraints
sudo -u postgres psql social < $1/sitemap_definition/005-constraint.sql

# PAYMENT SQL IMPORTS

# create sequences
sudo -u postgres psql social < $1/payment_definition/002-schema.sql

# create sequences
sudo -u postgres psql social < $1/payment_definition/003-sequence.sql

# create tables
sudo -u postgres psql social < $1/payment_definition/004-table.sql

# create constraints
sudo -u postgres psql social < $1/payment_definition/005-constraint.sql

sudo -u postgres psql social < $1/payment_definition/006-paymentro.sql

# modifications
sudo -u postgres psql social < $1/payment_definition/modifications/001-add-koding-to-enum.sql

sudo -u postgres psql social < $1/payment_definition/modifications/002-add-betatester-plan.sql

# create sequences
psql $WERCKER_POSTGRESQL_URL < $1/integration_definition/002-schema.sql

# create sequences
psql $WERCKER_POSTGRESQL_URL < $1/integration_definition/003-sequence.sql

# create tables
psql $WERCKER_POSTGRESQL_URL < $1/integration_definition/004-table.sql

# create constraints
psql $WERCKER_POSTGRESQL_URL < $1/integration_definition/005-constraint.sql

# TODO: if you make changes to this file, don't forget `create-wercker.sh`
