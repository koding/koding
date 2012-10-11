#!/bin/bash
fullpath=/usr/sbin/pure-uploadscript
pid_file=/var/run/pure-uploadscript.pid
clamav_file=/etc/pure-ftpd/clamav_check.sh
cmd="$fullpath -B -r $clamav_file"

# Source function library.
. /etc/init.d/functions

start() {
        echo -n $"Starting $cmd: "
    	${cmd}
        PID=$(/usr/bin/pgrep -f "${cmd}")
	if [ -z ${pid_file} ];then
 	    echo "Can't start $0" 
	    exit 1
	else
            echo ${PID} > ${pid_file}
            exit 0
	fi
}

stop() {
        echo -n $"Stopping $prog: "
        killproc pure-uploadscript
        RETVAL=$?
        [ $RETVAL = 0 ] && rm -f /var/lock/subsys/pure-authd
        echo
}

# See how we were called.
case "$1" in
        start)
                start
                ;;
        stop)
                stop
                ;;
        restart)
                stop
                start
                ;;
        status)
                status pure-uploadscript
                RETVAL=$?
                if [ $RETVAL -eq 0 ] ; then
                    echo
                fi
                ;;
        *)
                echo $"Usage: $0 {start|stop|restart|status}"
                RETVAL=1
esac
exit $RETVAL
