/dev/pts
/proc
/var/run/proxyexec/cagefs.sock
/var/lib/sss
/Shared
# You can add personal (individual) mounts for users, like below.
# Please, start line with "@" symbol, and then specify path and permissions (comma separated).
# These directories will be virtualized for each user.
@/var/spool/cron,700
@/var/run/screen,777
@/var/lib/php/session,777
