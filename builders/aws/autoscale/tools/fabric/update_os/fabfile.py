
from fabric.api import put,run, env,roles,sudo
from fabric.network import disconnect_all
import os
import sys
sys.path.append(os.path.realpath("../libs"))
import as_nodes

env.user = 'ubuntu'
cmd = "export DEBIAN_FRONTEND=noninteractive ; /usr/bin/apt-get -q update && /usr/bin/apt-get -q -o Dpkg::Options::='--force-confold' -y upgrade; apt-get clean"

env.disable_known_hosts = True
#env.parallel            = True


#env.hosts = as_nodes.get_all_hosts()
env.roledefs = as_nodes.get_all_roles()



run_template_func = """@roles('%s')
def update_os_on_%s():
    \""" update OS packages on %s  \"""
    sudo(cmd)
"""

for role in env.roledefs:
	exec run_template_func % (role,role,role) 

