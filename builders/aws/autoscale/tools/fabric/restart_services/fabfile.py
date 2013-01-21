
from fabric.api import put,run, env,roles,sudo
from fabric.network import disconnect_all
import os
import sys
sys.path.append(os.path.realpath("../libs"))
import as_nodes

env.user = 'ubuntu'
cmd = "/usr/bin/killall -u koding -9 ;/usr/bin/supervisorctl start all "

env.disable_known_hosts = True
#env.parallel            = True


#env.hosts = as_nodes.get_all_hosts()
env.roledefs = as_nodes.get_all_roles()



run_template_func = """@roles('%s')
def restart_%s():
    \""" restart %s processes \"""
    sudo(cmd)
"""

for role in env.roledefs:
	exec run_template_func % (role,role,role) 

