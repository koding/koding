#!/usr/bin/env python

try:
    import os
    import sys
    import yaml
    import shlex
    import signal
    import psutil
    import subprocess
except ImportError:
    print "Missing Python module(s)"
    print "  pip install psutil"
    print "  pip install pyyml"


def run_command(cmd, logfile='/dev/null'):
    so = file(logfile, 'a+')
    p = subprocess.Popen(cmd, shell=False, universal_newlines=True, stdout=so)
    ret_code = p.wait()
    so.flush()
    return ret_code

def fork_command(cmd, logfile='/dev/null'):
    try: 
        pid = os.fork() 
        if pid > 0:
            return
    except OSError, e:
        sys.exit(1)

    os.setsid()

    try: 
        pid = os.fork() 
        if pid > 0:
            sys.exit(0) 
    except OSError, e: 
        sys.exit(1)

    si = file('/dev/null', 'r')
    so = file(logfile, 'a+')
    se = file(logfile, 'a+', 0)

    os.dup2(si.fileno(), sys.stdin.fileno())
    os.dup2(so.fileno(), sys.stdout.fileno())
    os.dup2(se.fileno(), sys.stderr.fileno())

    p = subprocess.Popen(cmd, stdout=so, stderr=se)

    os._exit(os.EX_OK)


def kill_group(proc, signal):
    children = proc.get_children()
    try:
        proc.send_signal(signal)
    except:
        pass
    for child in children:
        kill_group(child, signal)

def which(cmd):
    for dir in os.environ['PATH'].split(':'):
        exe = os.path.join(dir, cmd)
        if os.path.exists(exe):
            return exe

def get_process_path(cmd):
    exe = which(cmd)
    data = file(exe).read(100).split('\n')[0]
    if data.startswith('#!'):
        shebang = data.split('#!')[1]
        if shebang.startswith('/usr/bin/env'):
            app = os.path.realpath(which(shebang.split()[1]))
            return app + ' ' + exe
        else:
            return shebang + ' ' + exe
    else:
        return exe

def print_usage():
    print "Usage: %s <command> [service1 service2 ...]" % sys.argv[0]
    print "Example:"
    print "  %s list" % sys.argv[0]
    print "  %s start web" % sys.argv[0]
    print "  %s start web auth" % sys.argv[0]
    print "  %s stop all" % sys.argv[0]
    print "  %s start all" % sys.argv[0]
    print "  %s status" % sys.argv[0]
    print "  %s log" % sys.argv[0]

def main():
    run_dir = os.getcwd()
    run_file = os.path.join(run_dir, 'Runfile')

    if not os.access(run_file, os.R_OK):
        print "Nothing to do"
        return -1

    try:
        operation = sys.argv[1]
        services = sys.argv[2:]
    except IndexError:
        print_usage()
        return -1

    if operation not in ('start', 'stop', 'list', 'status', 'log'):
        print_usage()
        return -1

    if operation == 'log':
        os.system('tail -f *.log')
        return

    rules = yaml.load(file(run_file))

    if 'all' in services:
        services = rules.keys()

    if operation == 'list':
        for name in rules:
            print name
        return 0
    elif operation in ('start', 'stop'):
        unknown = set(services) - set(rules.keys())
        if len(unknown):
            print "Unknown service(s): %s" % ', '.join(unknown) 
            return -1
    elif operation == 'status':
        services = rules.keys()

    rule_commands = []
    for service in services:
        if isinstance(rules[service], str):
            rules[service] = [rules[service]]
        for i, cmd in enumerate(rules[service]):
            cmd = shlex.split(cmd)
            cmd = shlex.split(get_process_path(cmd[0])) + cmd[1:]
            rules[service][i] = cmd
            rule_commands.append(cmd)

    running_processes = []
    running_commands = []
    for process in psutil.process_iter():
        try:
            cwd = os.path.abspath(process.getcwd())
        except:
            continue
        cmd = process.cmdline
        if not len(cmd):
            continue
        cmd[0] = process.exe
        if cwd == run_dir:
            if cmd in rule_commands:
                running_processes.append(process)
                running_commands.append(cmd)

    if operation == 'status':
        for cmd in running_commands:
            for service in rules:
                if cmd in rules[service]:
                    print service
    elif operation == 'stop':
        for proc in running_processes:
            kill_group(proc, signal.SIGKILL)
    elif operation == 'start':
        for cmd in rule_commands:
            if cmd not in running_commands:
                fork_command(cmd, os.path.join(run_dir, "%s.log" % cmd[-1]))

    return 0

if __name__ == '__main__':
    sys.exit(main())