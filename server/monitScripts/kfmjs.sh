#!/bin/bash



#monit configuration:
#
#check process kfmjs
#	with pidfile /var/run/kfmjs.pid
#	start program = "/opt/kfmjs/server/monitScripts/kfmjs.sh start"
#		with timeout 30 seconds
#	stop program = "/opt/kfmjs/server/monitScripts/kfmjs.sh stop"
#		with timeout 30 seconds
#
#	if changed pid then alert
#	if totalcpu > 15% for 2 cycles then alert
#	if totalmem > 10 MB for 2 cycles then alert
#	if 3 restarts within 5 cycles then timeout


PATH=$PATH:'/opt/nodejs/bin'


APP_FILE='/tmp/kd-server.js'
APP_DIR='/opt/kfmjs'

PID_FILE="/var/run/kfmjs.pid"
LOG_FILE="/var/log/kfmjs.log"

cd ${APP_DIR}

CMD="node --max-stack-size=1073741824 ${APP_FILE} /opt/kfmjs beta 3000"

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
        exit 1
    else
        echo ${PID} > ${PID_FILE}
    fi


elif [ "$1" = "stop" ]; then
    if ( kill $(cat ${PID_FILE}) ); then
        echo "process ${APP_FILE} killed with 15" >> ${LOG_FILE}
        rm ${PID_FILE}
    else
        # I said - KILL!!
        kill -9 $(cat ${PID_FILE})
        echo "process ${APP_FILE} killed with 9 :(" >> ${LOG_FILE}
        rm ${PID_FILE}
    fi
else
    echo "Usage: $0 start/stop"
fi