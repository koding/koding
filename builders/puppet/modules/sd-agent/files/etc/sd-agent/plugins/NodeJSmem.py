#!/usr/bin/python

import os.path

pids_dir = '/var/run/node/'

class NodeJSMem (object):
    def __init__(self, agentConfig, checksLogger, rawConfig):
        self.agentConfig = agentConfig
        self.checksLogger = checksLogger
        self.rawConfig = rawConfig


    def getMemUsage (self,pid):
        proc_file = open('/proc/'+pid+'/status','r')
        data = proc_file.read()
        proc_file.close()
        return int(data[data.index('VmRSS'):].split()[1])/1024

    def get_processes (self):
        pid_files = os.listdir(pids_dir)
        process = {}
        for pid_file in pid_files:
            pid = open(os.path.join(pids_dir,pid_file))
            process[pid_file.split('.')[0]] =  pid.read().rstrip()
            pid.close()
        return process

    def run(self):
        data = {}
        for name,pid in self.get_processes().iteritems():
            data[name] = self.getMemUsage(pid)
        return data

