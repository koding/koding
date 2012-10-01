#!/bin/bash
# /etc/rc.d/init.d/stunnel
#
# Starts the stunnel daemon
#
# Source function library.
. /etc/init.d/functions
test -x /usr/bin/stunnel || exit 0
RETVAL=0
ulimit -n 2048
#
#       See how we were called.
#
prog="stunnel"
start() {
    # Check if stunnel is already running
    if [ ! -f /var/lock/subsys/stunnel ]; then
    echo -n $"Starting $prog: "
    daemon /usr/bin/stunnel
    RETVAL=$?
    [ $RETVAL -eq 0 ] && touch /var/lock/subsys/stunnel
    echo
    fi
    return $RETVAL
}
stop() {
    echo -n $"Stopping $prog: "
    killproc -p /var/run/stunnel/stunnel.pid
    RETVAL=$?
    [ $RETVAL -eq 0 ] && rm -f /var/lock/subsys/stunnel
    echo
    return $RETVAL
}
restart() {
    stop
    start
}
reload() {
    restart
}

case "$1" in
start)
    start
    ;;
stop)
    stop
    ;;
reload|restart)
    restart
    ;;
*)
    echo $"Usage: $0 {start|stop|restart}"
    exit 1
    
esac
exit $?
exit $RETVAL
