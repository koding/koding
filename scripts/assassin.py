#!/usr/bin/env python

import os
import time
import psutil

THRESHOLD = 90.0   # percentage
REPEAT_EVERY = 2   # seconds
MAX_OCCURRENCE = 5 # times

my_pid = os.getpid()
bad_guys = {}

def get_top_processes():

    procs = []

    for p in psutil.process_iter():

        if p.pid == my_pid:
            continue

        try:
            p.dict = p.as_dict(['get_cpu_percent', 'name', 'status'])

        except:
            pass

        else:
            if p.dict['cpu_percent'] > THRESHOLD:
                procs.append(p)

    # return processes sorted by CPU percent usage
    return sorted(procs, key=lambda p: p.dict['cpu_percent'], reverse = True)


def kill(proc):

    print "Killing: %s (PID %s)" % (proc.name(), proc.pid)
    proc.kill()
    del bad_guys[proc.pid]


def checks():

    global bad_guys

    top_process = get_top_processes()

    if len(top_process) == 0:
        bad_guys = {}
        return

    for proc in top_process[0:5]:
        if proc.pid in bad_guys:
            bad_guys[proc.pid]['counter'] += 1
            if bad_guys[proc.pid]['counter'] >= MAX_OCCURRENCE:
                kill(proc)
        else:
            bad_guys[proc.pid] = dict( proc = proc, counter = 0 )

    for pid, p in bad_guys.iteritems():
        [p, counter] = [p['proc'].dict, p['counter']]
        print "Process '%s' (PID %s) is using more than %s CPU (%s) in last %d seconds for the %d times." % (
            p['name'], pid, THRESHOLD, p['cpu_percent'], REPEAT_EVERY, counter
        )

def main():

    try:
        while True:
            checks()
            time.sleep(REPEAT_EVERY)

    except (KeyboardInterrupt, SystemExit):
        pass

if __name__ == '__main__':
    main()
