#!/usr/bin/python

import paramiko
import sys
import config

ssh_timeout = 4800.0

def doExec(commands,host,user,port=22):
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(
        paramiko.AutoAddPolicy())

    ssh.connect(host,port=port, username=user,
        key_filename=config.key_path,timeout=ssh_timeout)
    sys.stdout.write("connected\n")
    for command in commands:
        sys.stdout.write("Executing %s\n" % command)
        stdin, stdout, stderr = ssh.exec_command(command)
        if stdout:
            for line in stdout.readlines():
                sys.stdout.write(line)
        elif stderr:
            for err in stderr.readlines():
                sys.stderr.write(err)


if __name__ == '__main__':
    sys.exit(0)