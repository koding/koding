# create sequences
sudo -u postgres psql social < /opt/koding/go/src/socialapi/workers/sitemap/sql/002-schema.sql

# create sequences
sudo -u postgres psql social < /opt/koding/go/src/socialapi/workers/sitemap/sql/003-sequence.sql

# create tables
sudo -u postgres psql social < /opt/koding/go/src/socialapi/workers/sitemap/sql/004-table.sql

# create constraints
sudo -u postgres psql social < /opt/koding/go/src/socialapi/workers/sitemap/sql/005-constraint.sql