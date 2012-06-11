#!/bin/bash


#APP_FILE='/home/node/kfmjs/kd-server.js'
#APP_DIR='/home/node/kfmjs'
APP_DIR="/mnt/storage0/koding"
APP_FILE="${APP_DIR}/kd-server.js"

PID_FILE="/var/run/node/koding.pid"
LOG_FILE="/var/log/node/koding.log"
ALERT_MAIL="root"

export NODE_PATH=${APP_DIR}

cd ${APP_DIR}


CMD="/usr/bin/node --max-stack-size=1073741824 ${APP_FILE} ${APP_DIR} beta 3000"

if [ "$1" == "start" ]; then
    APP_PID=$(/usr/bin/pgrep -f ${APP_FILE})

  
    if [  ! -z ${APP_PID} ]; then
        echo "failed to start ${APP_FILE}. already running with pid ${APP_PID}" >> ${LOG_FILE}
	if [ ${APP_PID} -ne $(cat ${PID_FILE}) ]; then
	    echo "pid in pidfile ${PID_FILE} is wrong. monit will not work"  >> ${LOG_FILE}
	    echo "rewriting pidfile with current process pid" >> ${LOG_FILE}
	    echo ${APP_PID} > ${PID_FILE}
	    exit 0
	fi
        exit 1
    fi

    [ -e ${PID_FILE} ] && rm ${PID_FILE}

    echo "starting with ${CMD}" >> ${LOG_FILE}
    ${CMD} >>${LOG_FILE} 2>&1 &
    PID=$(/usr/bin/pgrep -f ${APP_FILE})
    if [ -z ${PID} ];then
        echo "Can't start $0" >> ${LOG_FILE}
        /usr/bin/tail -n50  $LOG_FILE | /bin/mail -s $APP_FILE $ALERT_MAIL
        exit 1
    else
        echo ${PID} > ${PID_FILE}
        sleep 5
        /usr/bin/tail -n50  $LOG_FILE | /bin/mail -s $APP_FILE $ALERT_MAIL
    fi


elif [ "$1" = "stop" ]; then
    if  kill -9 $(cat ${PID_FILE}) ; then
        sleep 5
        echo "process ${APP_FILE} killed with 9" >> ${LOG_FILE}
        rm ${PID_FILE}
    fi
else
    echo "Usage: $0 start/stop"
fi


