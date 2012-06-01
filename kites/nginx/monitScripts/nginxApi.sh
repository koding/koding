#!/bin/bash

PATH=$PATH:'/opt/nodejs/bin'

APP_DIR='/opt/kfmjs/kites/nginx/'
APP_FILE='Nginx-client.coffee'


PID_FILE="/var/run/nginxApi.pid"
LOG_FILE="/var/log/nginxApi.log"

cd ${APP_DIR}
if [ "$1" == "start" ]; then
    if [[ -e ${PID_FILE} ]] &&  ps aux | grep $(cat ${PID_FILE})|grep -v grep 1>>/dev/null 2>> ${LOG_FILE} ; then
        echo "failed to start $0. already running" >> ${LOG_FILE}
        exit 1
    fi

    if [ -e ${PID_FILE} ];then
        rm ${PID_FILE}
    fi

    echo "starting with coffee ${APP_FILE}" >> ${LOG_FILE}
    if  ! coffee ${APP_FILE} >>${LOG_FILE} 2>&1 ; then
        echo "Can't start $0" >> ${LOG_FILE}
        exit 1
    fi


elif [ "$1" = "stop" ]; then
    if  kill $(cat ${PID_FILE}) 2>> ${LOG_FILE} ; then
        echo "process ${APP_FILE} killed with 15" >> ${LOG_FILE}
        rm ${PID_FILE}
    else
        echo "Can't kill ${APP_FILE}"
    fi
else
    echo "Usage: $0 start/stop"
fi




