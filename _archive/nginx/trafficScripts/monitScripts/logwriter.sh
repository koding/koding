#!/bin/bash

#check process logwriter
#	with pidfile /var/run/logwriter.pid
#	start program = "/opt/kfmjs/kites/nginx/trafficScripts/monitScripts/logwriter.sh start"
#		with timeout 30 seconds
#	stop program = "/opt/kfmjs/kites/nginx/trafficScripts/monitScripts/logwriter.sh stop"
#		with timeout 30 seconds
#
#	if changed pid then alert
#	if totalcpu > 15% for 2 cycles then alert
#	if totalmem > 30 MB for 2 cycles then alert
#	if 3 restarts within 5 cycles then timeout



PID_FILE="/var/run/logwriter.pid"
NGINX_LOG_FILE="/var/log/nginx/hosting.traffic.log"
APP_LOG="/var/log/logwriter.log"
APP="/opt/kfmjs/kites/nginx/trafficScripts/logwriter.py"
CMD="/usr/bin/tail -Fn1 ${NGINX_LOG_FILE}"

if [ "$1" == "start" ]; then
    if [[ -e ${PID_FILE} ]] &&  ps aux | grep $(cat ${PID_FILE})|grep -v grep 1>>/dev/null 2>> ${APP_LOG} ; then
        echo "failed to start $0. already running" >> ${APP_LOG}
        exit 1
    fi

    if [ -e ${PID_FILE} ];then
        rm ${PID_FILE}
    fi

    echo "starting with ${CMD}" >> ${APP_LOG}
    if  ! ${CMD} | ${APP} >>${APP_LOG} 2>&1 ; then
        echo "Can't start $0" >> ${APP_LOG}
        exit 1
    fi


elif [ "$1" = "stop" ]; then
    if  kill $(cat ${PID_FILE}) 2>> ${APP_LOG} ; then
        echo "process ${APP_LOG} killed with 15" >> ${APP_LOG}
        rm ${PID_FILE}
    else
        echo "Can't kill ${APP_LOG}"
    fi
else
    echo "Usage: $0 start/stop"
fi





