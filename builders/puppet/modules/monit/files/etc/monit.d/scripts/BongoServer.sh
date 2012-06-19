#!/bin/bash

APP_DIR='/opt/kfmjs/kites/'
APP_FILE='bongo-server.coffee'


PID_FILE="/var/run/node/BongoServer.pid"
LOG_FILE="/var/log/node/BongoServer.log"

CMD="coffee $APP_FILE"
cd ${APP_DIR}
if [ "$1" == "start" ]; then
        if [[ -e ${PID_FILE} ]] && ps aux | grep $(cat ${PID_FILE})|grep -v grep 1>>/dev/null 2>> ${LOG_FILE} ; then
                echo "failed to start $0. already running" >> $LOG_FILE
                exit 1
        fi

        echo "starting with '${CMD}'" >> ${LOG_FILE}
        ${CMD} >>${LOG_FILE} 2>&1 &

        PID=$(pgrep -f ${APP_FILE})
        if [ -z ${PID} ];then
            echo "Can't start $0" >> ${LOG_FILE}
            exit 1
        else
	    echo "started with '${CMD}' from ${APP_DIR}" >> ${LOG_FILE}
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