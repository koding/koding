#!/bin/bash
ZABBIX_CONF="/etc/zabbix/zabbix_agentd.conf.d/mailq.conf"
ZABBIX_SENDER="/usr/bin/zabbix_sender"
ZABBIX_HOST="mon.prod.system.aws.koding.com"
ZABBIX_PORT="10051"
ZABBIX_KEY="mailq.size"



queue=$(/usr/sbin/postqueue -p |/usr/bin/tail -n1|/bin/cut -d' ' -f5)
if echo ${queue}|grep -q [0-9] >/dev/null; then
    ${ZABBIX_SENDER} -z ${ZABBIX_HOST} -p ${ZABBIX_PORT} -s ${HOSTNAME} -k ${ZABBIX_KEY} -o ${queue} >/dev/null
else
    ${ZABBIX_SENDER} -z ${ZABBIX_HOST} -p ${ZABBIX_PORT} -s ${HOSTNAME} -k ${ZABBIX_KEY} -o 0 >/dev/null
fi

