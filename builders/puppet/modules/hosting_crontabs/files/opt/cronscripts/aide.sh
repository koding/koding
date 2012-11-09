#!/bin/bash
ZABBIX_SENDER="/usr/bin/zabbix_sender"
ZABBIX_HOST="mon.prod.system.aws.koding.com"
ZABBIX_PORT="10051"
ZABBIX_KEY="aide.result"

/usr/sbin/aide --check >> /var/log/aide.log 

${ZABBIX_SENDER} -z ${ZABBIX_HOST} -p ${ZABBIX_PORT} -s ${HOSTNAME} -k ${ZABBIX_KEY} -o $? >/dev/null
