#!/bin/bash

declare psql_prog=$(which psql)

function psql() {
  local dbname=${KONFIG_POSTGRES_URL:-$1}
  shift
  $psql_prog $dbname "$@"
}

pushd $(dirname $0)/..

# clear database
psql postgres --file definition/000-cleanup.sql

# add UTF-8 support
psql postgres --file definition/000-UTF8.sql

# create initial database
psql postgres --file definition/001-database.sql

# create  schema definitions
psql social --file definition/002-schema.sql

# create sequences
psql social --file definition/003-sequence.sql

# create sequence functions
psql social --file definition/003-sequencefunction.sql

# create tables
psql social --file definition/004-table.sql

# ctreate constraints
 psql social --file definition/005-constraint.sql

# create kontrol specific tables
if [ -d "kontrol" ]; then
  psql social --file kontrol/001-schema.sql
  psql social --file kontrol/002-table.sql
fi

# NOTIFICATION WORKER SQL IMPORTS

# create sequences
psql social --file notification_definition/002-schema.sql

# create sequences
psql social --file notification_definition/003-sequence.sql

# create tables
psql social --file notification_definition/004-table.sql

# create constraints
psql social --file notification_definition/005-constraint.sql

# SITEMAP WORKER SQL IMPORTS

# create sequences
psql social --file sitemap_definition/002-schema.sql

# create sequences
psql social --file sitemap_definition/003-sequence.sql

# create tables
psql social --file sitemap_definition/004-table.sql

# create constraints
psql social --file sitemap_definition/005-constraint.sql

# PAYMENT SQL IMPORTS

# create sequences
psql social --file payment_definition/002-schema.sql

# create sequences
psql social --file payment_definition/003-sequence.sql

# create tables
psql social --file payment_definition/004-table.sql

# create constraints
psql social --file payment_definition/005-constraint.sql

psql social --file payment_definition/006-paymentro.sql

# create sequences
psql social --file integration_definition/002-schema.sql

# create sequences
psql social --file integration_definition/003-sequence.sql

# create tables
psql social --file integration_definition/004-table.sql

# create constraints
psql social --file integration_definition/005-constraint.sql
