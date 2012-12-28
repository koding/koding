#!/bin/bash
PATH=$PATH:'/opt/nodejs/bin'

APP_DIR='/opt/kfmjs/kites/openVZ/'
APP_FILE='OpenVZ-client.coffee'
SERVER_ENV='prod'

PID_FILE="/var/run/OpenVZ-client-${SERVER_ENV}.pid"
LOG_FILE="/var/log/OpenVZ-client-${SERVER_ENV}.log"

cd ${APP_DIR}
if [ "$1" == "start" ]; then
        if [[ -e ${PID_FILE} ]] || ( pgrep -f ${APP_FILE} ) ; then
                echo "failed to start $0. already running" >> ${LOG_FILE}
                exit 1
        fi
        echo "SERVER_ENV=${SERVER_ENV} coffee ${APP_FILE}"
        if ( SERVER_ENV=${SERVER_ENV} coffee ${APP_FILE} >>$LOG_FILE 2>&1   & ); then
                sleep 5
        else
                echo "failed to start $0" 
                exit 1
        fi
elif [ "$1" == "stop" ]; then
        kill $(cat ${PID_FILE}) && rm ${PID_FILE}
else
        echo "Usage: $0 start/stop"
fi
