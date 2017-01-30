if [ -d "$1" ]; then
  cd $1
fi

# clear database
sudo -u postgres psql postgres --file definition/000-cleanup.sql

# add UTF-8 support
sudo -u postgres psql postgres --file definition/000-UTF8.sql

# create initial database
sudo -u postgres psql postgres --file definition/001-database.sql

# create  schema definitions
sudo -u postgres psql social --file definition/002-schema.sql

# create sequences
sudo -u postgres psql social --file definition/003-sequence.sql

# create sequence functions
sudo -u postgres psql social --file definition/003-sequencefunction.sql

# create tables
sudo -u postgres psql social --file definition/004-table.sql

# ctreate constraints
sudo -u postgres  psql social --file definition/005-constraint.sql

# create kontrol specific tables
if [ -d "kontrol" ]; then
  sudo -u postgres psql social --file kontrol/001-schema.sql
  sudo -u postgres psql social --file kontrol/002-table.sql
fi

# NOTIFICATION WORKER SQL IMPORTS

# create sequences
sudo -u postgres psql social --file notification_definition/002-schema.sql

# create sequences
sudo -u postgres psql social --file notification_definition/003-sequence.sql

# create tables
sudo -u postgres psql social --file notification_definition/004-table.sql

# create constraints
sudo -u postgres psql social --file notification_definition/005-constraint.sql

# SITEMAP WORKER SQL IMPORTS

# create sequences
sudo -u postgres psql social --file sitemap_definition/002-schema.sql

# create sequences
sudo -u postgres psql social --file sitemap_definition/003-sequence.sql

# create tables
sudo -u postgres psql social --file sitemap_definition/004-table.sql

# create constraints
sudo -u postgres psql social --file sitemap_definition/005-constraint.sql

# PAYMENT SQL IMPORTS

# create sequences
sudo -u postgres psql social --file payment_definition/002-schema.sql

# create sequences
sudo -u postgres psql social --file payment_definition/003-sequence.sql

# create tables
sudo -u postgres psql social --file payment_definition/004-table.sql

# create constraints
sudo -u postgres psql social --file payment_definition/005-constraint.sql

sudo -u postgres psql social --file payment_definition/006-paymentro.sql

# create sequences
sudo -u postgres psql social --file integration_definition/002-schema.sql

# create sequences
sudo -u postgres psql social --file integration_definition/003-sequence.sql

# create tables
sudo -u postgres psql social --file integration_definition/004-table.sql

# create constraints
sudo -u postgres psql social --file integration_definition/005-constraint.sql

# TODO: if you make changes to this file, don't forget `create-wercker.sh`
