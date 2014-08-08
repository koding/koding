
# add UTF-8 support
psql $WERCKER_POSTGRESQL_URL < $1/definition/000-UTF8.sql

# create initial database
psql $WERCKER_POSTGRESQL_URL < $1/definition/001-database.sql

# create  schema definitions
psql social < $1/definition/002-schema.sql

# create sequences
psql social < $1/definition/003-sequence.sql

# create sequence functions
psql social < $1/definition/003-sequencefunction.sql

# create tables
psql social < $1/definition/004-table.sql

# create constraints
psql social < $1/definition/005-constraint.sql

# NOTIFICATION WORKER SQL IMPORTS

# create sequences
psql social < $1/notification_definition/002-schema.sql

# create sequences
psql social < $1/notification_definition/003-sequence.sql

# create tables
psql social < $1/notification_definition/004-table.sql

# create constraints
psql social < $1/notification_definition/005-constraint.sql

# SITEMAP WORKER SQL IMPORTS

# create sequences
psql social < $1/sitemap_definition/002-schema.sql

# create sequences
psql social < $1/sitemap_definition/003-sequence.sql

# create tables
psql social < $1/sitemap_definition/004-table.sql

# create constraints
psql social < $1/sitemap_definition/005-constraint.sql
