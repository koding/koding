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
    if [[ -e ${PID_FILE} ]] &&  ps aux | grep $(cat ${PID_FILE})|grep -v grep 1>>/dev/null 2>> ${LOG_FILE}; then
        echo "failed to start $0. already running" >> ${LOG_FILE}
        exit 1
    fi

    if [ -e ${PID_FILE} ];then
        rm ${PID_FILE}
    fi

    echo "starting with ${CMD}" >> ${LOG_FILE}
    ${CMD} >>${LOG_FILE} 2>&1 &
    PID=$(pgrep -f ${APP_FILE})
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
