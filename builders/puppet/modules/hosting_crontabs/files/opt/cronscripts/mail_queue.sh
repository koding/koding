#!/bin/bash
ZABBIX_CONF="/etc/zabbix/zabbix_agentd.conf.d/mailq.conf"


queue=$(/usr/sbin/postqueue -p |/usr/bin/tail -n1|/bin/cut -d' ' -f5)
if echo ${queue}|grep -q [0-9] >/dev/null; then
    echo "UserParameter=mailq.size,echo ${queue}" > ${ZABBIX_CONF}
else
    echo "UserParameter=mailq.size,echo 0" > ${ZABBIX_CONF}
fi
