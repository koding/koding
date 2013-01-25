
from fabric.api import put,run, env,roles,sudo
from fabric.network import disconnect_all
import os
import sys
sys.path.append(os.path.realpath("../libs"))
import as_nodes

env.user = 'ubuntu'

env.disable_known_hosts = True
#env.parallel            = True


#env.hosts = as_nodes.get_all_hosts()
env.roledefs = as_nodes.get_all_roles()

try:
	cmd = os.environ['FAB_CMD']
except KeyError:
	sys.stderr.write("USAGE: export FAB_CMD='command'; fab <fabric_command>\n")
	sys.exit(1)

run_template_func = """@roles('%s')
def runOn_%s():
    \""" run sudo command on %s \"""
    sudo(cmd)
"""

for role in env.roledefs:
	exec run_template_func % (role,role,role) 

