#!/bin/bash
fullpath=/usr/sbin/pure-authd
pid_file=/var/run/pure-authd.pid
sock_file=/var/run/ftpd.sock
auth_file=/opt/authapp/mongoAuth.py
log_file=/var/log/ftp.log
cmd="$fullpath -B -p $pid_file -s $sock_file -r $auth_file"

# Source function library.
. /etc/init.d/functions

start() {
        echo -n $"Starting $cmd: "
        $cmd >> $log_file
        RETVAL=$?
        [ $RETVAL = 0 ] && touch /var/lock/subsys/pure-authd
        echo
}

stop() {
        echo -n $"Stopping $prog: "
        killproc pure-authd
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
                status pure-authd
                RETVAL=$?
                if [ $RETVAL -eq 0 ] ; then
                    echo
                fi
                ;;
        *)
                echo $"Usage: pure-authd {start|stop|restart|status}"
                RETVAL=1
esac
exit $RETVAL
