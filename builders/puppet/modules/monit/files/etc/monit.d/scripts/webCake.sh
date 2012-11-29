#!/bin/bash

BASE_DIR="/mnt/storage0/koding2"
APP_DIR="${BASE_DIR}"
LOG_FILE="/var/log/node/webCake.log"
PID_FILE="/var/run/node/webCake.pid"
OPTIONS="-c prod run"
CAKE="/usr/bin/cake"

CMD="${CAKE} ${OPTIONS}"
cd ${APP_DIR}
if [ "$1" == "start" ]; then
    if  ! ${CMD} >> ${LOG_FILE} 2>&1  ; then
        echo "Can't start ${CMD}" >> ${LOG_FILE}
        exit 1
    fi

elif [ "$1" = "stop" ]; then
    if  kill $(cat ${PID_FILE}) 2>> ${LOG_FILE} ; then
        echo "${CMD} killed with 15" >> ${LOG_FILE}
        rm ${PID_FILE}
    else
        echo "Can't kill ${CMD} with pid file ${PID_FILE}"
    fi
else
    echo "Usage: $0 start/stop"
fi
