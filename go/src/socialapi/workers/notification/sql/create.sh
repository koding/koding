# create sequences
sudo -u postgres psql social < /opt/koding/go/src/socialapi/workers/notification/sql/002-schema.sql

# create sequences
sudo -u postgres psql social < /opt/koding/go/src/socialapi/workers/notification/sql/003-sequence.sql

# create tables
sudo -u postgres psql social < /opt/koding/go/src/socialapi/workers/notification/sql/004-table.sql

# create constraints
sudo -u postgres psql social < /opt/koding/go/src/socialapi/workers/notification/sql/005-constraint.sql