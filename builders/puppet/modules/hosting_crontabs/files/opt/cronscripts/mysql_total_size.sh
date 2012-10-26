#!/bin/bash
MYSQL_HOST="mysql0.db.koding.com"
MYSQL_USER="system"
MYSQL_PW="gTW9ts2A4PXyECd69MQNAKx8v988x27cxFAu73pv"

MYSQL_CMD="/usr/bin/mysql -h $MYSQL_HOST -u$MYSQL_USER -p$MYSQL_PW -N"

ZABBIX_CONF="/etc/zabbix/zabbix_agentd.conf.d/mysql_total_size.conf"

SIZE=`echo "select sum($(case "$3" in both|"") echo "data_length+index_length";; data|index) echo "$3_length";; free) echo "data_free";; esac)) from information_schema.tables$([[ "$1" = "all" || ! "$1" ]] || echo " where table_schema='$1'")$([[ "$2" = "all" || ! "$2" ]] || echo "and table_name='$2'");" | $MYSQL_CMD`

echo "UserParameter=mysql.size[*],echo $SIZE" > $ZABBIX_CONF
