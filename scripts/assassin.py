#!/usr/bin/env python

import os
import sys

import time
import json

import psutil
import pycurl

THRESHOLD      = 90.0 # percentage
REPEAT_EVERY   = 5    # seconds
MAX_OCCURRENCE = 5    # times
KILL_ENABLED   = False

my_pid   = os.getpid()
bad_guys = {}

PAYLOAD  = {
    "channel"    : "#_devops",
    "username"   : "py_assassin",
    "icon_emoji" : ":snake:"
}

slack = pycurl.Curl()
slack.setopt(pycurl.URL, "https://hooks.slack.com/services/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")
slack.setopt(pycurl.POST, 1)

def slack_it(message):

    print message

    PAYLOAD['text'] = message
    slack.setopt(pycurl.POSTFIELDS, "payload=%s" % json.dumps(PAYLOAD))
    slack.perform()


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

    slack_it("Killing: %s (PID %s)" % (proc.name(), proc.pid))
    if KILL_ENABLED:
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

    PROCESS_OUT = "Process '%s' (PID %s) is using more than %s " \
                  "CPU (%s) in last %d seconds for the %d times."

    for pid, p in bad_guys.iteritems():
        [p, counter] = [p['proc'].dict, p['counter']]
        slack_it(PROCESS_OUT % (
            p['name'], pid, THRESHOLD, p['cpu_percent'], REPEAT_EVERY, counter
        ))

def main():

    try:
        while True:
            checks()
            time.sleep(REPEAT_EVERY)

    except (KeyboardInterrupt, SystemExit):
        pass

if __name__ == '__main__':
    print "Assassin started..."
    main()
