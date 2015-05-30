# add UTF-8 support
psql $WERCKER_POSTGRESQL_URL < $1/definition/000-UTF8.sql

# create initial database
psql $WERCKER_POSTGRESQL_URL < $1/definition/001-database.sql

# create  schema definitions
psql $WERCKER_POSTGRESQL_URL < $1/definition/002-schema.sql

# create sequences
psql $WERCKER_POSTGRESQL_URL < $1/definition/003-sequence.sql

# create sequence functions
psql $WERCKER_POSTGRESQL_URL < $1/definition/003-sequencefunction.sql

# create tables
psql $WERCKER_POSTGRESQL_URL < $1/definition/004-table.sql

# create constraints
psql $WERCKER_POSTGRESQL_URL < $1/definition/005-constraint.sql

# NOTIFICATION WORKER SQL IMPORTS

# create sequences
psql $WERCKER_POSTGRESQL_URL < $1/notification_definition/002-schema.sql

# create sequences
psql $WERCKER_POSTGRESQL_URL < $1/notification_definition/003-sequence.sql

# create tables
psql $WERCKER_POSTGRESQL_URL < $1/notification_definition/004-table.sql

# create constraints
psql $WERCKER_POSTGRESQL_URL < $1/notification_definition/005-constraint.sql

# SITEMAP WORKER SQL IMPORTS

# create sequences
psql $WERCKER_POSTGRESQL_URL < $1/sitemap_definition/002-schema.sql

# create sequences
psql $WERCKER_POSTGRESQL_URL < $1/sitemap_definition/003-sequence.sql

# create tables
psql $WERCKER_POSTGRESQL_URL < $1/sitemap_definition/004-table.sql

# create constraints
psql $WERCKER_POSTGRESQL_URL < $1/sitemap_definition/005-constraint.sql

# PAYMENT WORKER SQL IMPORTS

# create sequences
psql $WERCKER_POSTGRESQL_URL < $1/payment_definition/002-schema.sql

# create sequences
psql $WERCKER_POSTGRESQL_URL < $1/payment_definition/003-sequence.sql

# create tables
psql $WERCKER_POSTGRESQL_URL < $1/payment_definition/004-table.sql

# create constraints
psql $WERCKER_POSTGRESQL_URL < $1/payment_definition/005-constraint.sql

# modifications
psql $WERCKER_POSTGRESQL_URL < $1/payment_definition/modifications/001-add-koding-to-enum.sql

psql $WERCKER_POSTGRESQL_URL < $1/payment_definition/modifications/002-add-betatester-plan.sql

# create sequences
psql $WERCKER_POSTGRESQL_URL < $1/integration_definition/002-schema.sql

# create sequences
psql $WERCKER_POSTGRESQL_URL < $1/integration_definition/003-sequence.sql

# create tables
psql $WERCKER_POSTGRESQL_URL < $1/integration_definition/004-table.sql

# create constraints
psql $WERCKER_POSTGRESQL_URL < $1/integration_definition/005-constraint.sql

# TODO: if you make changes to this file, don't forget `create.sh`
