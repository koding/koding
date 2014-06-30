dropdb postgres
createdb postgres

# create initial database
psql postgres < /definition/000-UTF8.sql

psql postgres < /definition/001-database.sql

# create  schema definitions
psql social < /definition/002-schema.sql

# create sequences
psql social < /definition/003-sequence.sql

# create sequence functions
psql social < /definition/003-sequencefunction.sql

# create tables
psql social < /definition/004-table.sql

# ctreate constraints
psql social < /definition/005-constraint.sql

# NOTIFICATION WORKER SQL IMPORTS

# create sequences
psql social < /notification_sql/002-schema.sql

# create sequences
psql social < /notification_sql/003-sequence.sql

# create tables
psql social < /notification_sql/004-table.sql

# create constraints
psql social < /notification_sql/005-constraint.sql