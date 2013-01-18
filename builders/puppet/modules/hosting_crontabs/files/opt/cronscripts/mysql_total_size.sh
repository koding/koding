#!/bin/bash
MYSQL_HOST="mysql0.db.koding.com"
MYSQL_USER="system"
MYSQL_PW="gTW9ts2A4PXyECd69MQNAKx8v988x27cxFAu73pv"

ZABBIX_SENDER="/usr/bin/zabbix_sender"
ZABBIX_HOST="mon.prod.system.aws.koding.com"
ZABBIX_PORT="10051"
ZABBIX_KEY="mysql.size"


MYSQL_CMD="/usr/bin/mysql -h $MYSQL_HOST -u$MYSQL_USER -p$MYSQL_PW -N"


SIZE=`echo "select sum($(case "$3" in both|"") echo "data_length+index_length";; data|index) echo "$3_length";; free) echo "data_free";; esac)) from information_schema.tables$([[ "$1" = "all" || ! "$1" ]] || echo " where table_schema='$1'")$([[ "$2" = "all" || ! "$2" ]] || echo "and table_name='$2'");" | $MYSQL_CMD`

SIZE=`echo "scale=0; ${SIZE}/1024/1024"|bc -l`
${ZABBIX_SENDER} -z ${ZABBIX_HOST} -p ${ZABBIX_PORT} -s ${HOSTNAME} -k ${ZABBIX_KEY} -o ${SIZE} >/dev/null
