
from fabric.api import put,run, env,roles,sudo
from fabric.network import disconnect_all
import os
import sys
sys.path.append(os.path.realpath("../libs"))
import as_nodes

env.user = 'ubuntu'
cmd = "/etc/init.d/chef-client restart"

env.disable_known_hosts = True
#env.parallel            = True


#env.hosts = as_nodes.get_all_hosts()
env.roledefs = as_nodes.get_all_roles()



run_template_func = """@roles('%s')
def speedup_deploy_on_%s():
    \""" speedup deploy on  %s  \"""
    sudo(cmd)
"""

for role in env.roledefs:
	exec run_template_func % (role,role,role) 

