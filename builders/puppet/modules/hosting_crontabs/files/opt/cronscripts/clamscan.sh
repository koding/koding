#!/bin/bash

LOCK="/var/lock/subsys/clamd_multiscan"

if [ ! -e ${LOCK} ] ; then
        /bin/touch ${LOCK}
        /usr/bin/ionice -c 3 -p $(cat /var/run/clamav/clamd.pid)
        /bin/echo -e "MULTISCAN /Users" | /usr/bin/nc localhost 13310
        /bin/rm ${LOCK}
else
        exit 1
fi

exit 0
