# Settings
## Set archive_command in postgresql.conf
```
archive_mode    = on
# test is there not to overwrite it
archive_command = 'test ! -f /backup/postgresql/wal_archive/%f && cp %p /backup/postgresql/wal_archive/%f'
```
