#!/usr/bin/python
import ssh_exec

def convert(ip,fqdn):

    commands = [
        "/sbin/sysctl -w kernel.hostname=%s" % fqdn,
        'curl http://repo.cloudlinux.com/cloudlinux/sources/cln/centos2cl > /tmp/centos2cl',
        'sh /tmp/centos2cl -k 4555-b4507cea4885d1d0df2edf70ee0d52da',
        '/usr/bin/yum -y install lve cagefs pam_lve lve-kmod --enablerepo=cloudlinux-updates-testing',
        ]
    ssh_exec.doExec(commands,ip,'root')

def reboot(ip):
    commands = ['reboot']
    ssh_exec.doExec(commands,ip,'root')

