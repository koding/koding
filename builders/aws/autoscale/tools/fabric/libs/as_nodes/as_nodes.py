import os
import sys
sys.path.append(os.path.realpath(".."))
import aws



socialworker = aws.get_addresses('socialworker')
authworker  = aws.get_addresses('authworker')
web_server = aws.get_addresses('web_server')


def get_all_hosts():
	return socialworker + authworker + web_server

def get_all_roles():
	return {
	    'socialworker': socialworker,
	    'authworker': authworker,
	    'web_server': web_server,
	}

