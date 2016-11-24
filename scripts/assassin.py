#!/usr/bin/env python

import os
import sys
import time
import json
import socket
import commands

try:
    import psutil
    import pycurl
except ImportError:
    print "Install required packages first: pip install psutil pycurl"
    sys.exit(1)

THRESHOLD      = 1.0  # percentage
KILL_THRESHOLD = 3.0  # average percentage before deciding to kill
REPEAT_EVERY   = 1    # seconds
MAX_OCCURRENCE = 5    # times
MAX_REPEAT     = 10   # times ~ 0 to infinite

KILL_ENABLED   = False
SLACK_ENABLED  = False

WHITE_LIST     = [
    "kloud",
    "koding-webserver",
    "koding-authworker",
    "koding-socialworker",
]

(status, hostaddr) = commands.getstatusoutput(
    "/opt/aws/bin/ec2-metadata --public-hostname"
)

hostname = socket.gethostname()

if status == 0:
    hostaddr = "ssh://ec2-user@%s" % hostaddr.split(':')[-1].strip()
    hostname = "<%s|%s>" % (hostaddr, hostname)
else:
    hostname = "*%s*" % hostname

my_pid   = os.getpid()
bad_guys = {}

PAYLOAD  = {
    "channel"    : "#_devops",
    "username"   : "py_assassin",
    "icon_emoji" : ":snake:"
}

slack = pycurl.Curl()
slack.setopt(pycurl.URL, "")
slack.setopt(pycurl.POST, 1)

def slack_it(message):

    print message

    if not SLACK_ENABLED:
        return

    PAYLOAD['text'] = "[%s] %s" % (hostname, message)
    slack.setopt(pycurl.POSTFIELDS, "payload=%s" % json.dumps(PAYLOAD))
    slack.perform()


def get_top_processes():

    procs = []

    for p in psutil.process_iter():

        if p.pid == my_pid:
            continue

        try:
            p.dict = p.as_dict(['cpu_percent', 'name', 'status'])

        except:
            pass

        else:
            if p.dict['cpu_percent'] > THRESHOLD:
                procs.append(p)

    # return processes sorted by CPU percent usage
    return sorted(procs, key=lambda p: p.dict['cpu_percent'], reverse = True)


def kill(proc, usage):

    usage = usage / MAX_OCCURRENCE # get average CPU usage

    if usage > KILL_THRESHOLD:

        if KILL_ENABLED and proc.name() in WHITE_LIST:

            slack_it("Killing: *%s* (*PID %s*) usage was: %s" %
                    (proc.name(), proc.pid, usage))

            proc.kill()

        else:

            print("If I was able to, I would like to kill: *%s* (*PID %s*) "
                  "since it's using %s cpu on average..." %
                    (proc.name(), proc.pid, usage))

    else:

        print("Giving another chance to *%s* since "
              "its usage average (*%s*) below kill "
              "threshold: *%s* " % (proc.name(), usage, KILL_THRESHOLD))

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
            bad_guys[proc.pid]['cpu'] += proc.dict['cpu_percent']
            if bad_guys[proc.pid]['counter'] >= MAX_OCCURRENCE:
                kill(proc, bad_guys[proc.pid]['cpu'])
        else:
            bad_guys[proc.pid] = dict( proc = proc, counter = 0, cpu = 0 )

    PROCESS_OUT = "Process '%s' (PID %s) is using more than %s " \
                  "CPU (%s) in last %d seconds for the %d times."

    for pid, p in bad_guys.iteritems():
        [p, counter] = [p['proc'].dict, p['counter']]
        print(PROCESS_OUT % (
            p['name'], pid, THRESHOLD, p['cpu_percent'], REPEAT_EVERY, counter
        ))

def main():

    counter = 0

    while True:

        checks()

        counter += 1

        if counter == MAX_REPEAT:
            print("Done.")
            sys.exit()

        time.sleep(REPEAT_EVERY)

if __name__ == '__main__':
    print "Assassin started..."

    try:
        main()
    except (KeyboardInterrupt, SystemExit):
        pass
