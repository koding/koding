#!/bin/sh
/bin/echo -e "SCAN $1" | /usr/bin/nc localhost 3310 |/bin/grep FOUND && /bin/echo $1 | /bin/mail -s "virus on ftp" aleksey@koding.com
