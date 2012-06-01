#!/usr/bin/env python
__author__ = 'Aleksey Mykhailov'
__email__  = 'aleksey@kodingen.com'

import sys, time
from daemon import Daemon
from traffCalc import TrafficStatistic
import config


class StatDaemon(Daemon):
    def run(self):
        """
        start daemon
        """
        traff = TrafficStatistic(config)
        while True:
            traff.calculate()
            time.sleep(0.5)


if __name__ == "__main__":
    daemon = StatDaemon(config.traff_calc_pid_file)
    if len(sys.argv) == 2:
        if 'start' == sys.argv[1]:
            daemon.start()
            print('started')
        elif 'stop' == sys.argv[1]:
            daemon.stop()
        elif 'restart' == sys.argv[1]:
            daemon.restart()
        else:
            print "Unknown command"
            sys.exit(2)
        sys.exit(0)
    else:
        print "usage: %s start|stop|restart" % sys.argv[0]
        sys.exit(2)