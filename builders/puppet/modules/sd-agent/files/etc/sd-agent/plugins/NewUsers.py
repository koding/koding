#!/usr/bin/python

import ldap
import os.path

ldap_uri = 'ldap://ldap1.prod.system.aws.koding.com'
ldap_user = 'uid=KAdmin,ou=Special Users,dc=koding,dc=com'
ldap_pass = 'sOg4:L]iM7!_UV-H'
ldap_base = 'dc=koding,dc=com'
tmp_file  = '/var/tmp/.ldap_id'

class NewUsers (object):
    def __init__(self, agentConfig, checksLogger, rawConfig):
        self.agentConfig = agentConfig
        self.checksLogger = checksLogger
        self.rawConfig = rawConfig


    def get_user_id(self):
    	conn = ldap.initialize(ldap_uri)
    	conn.bind(ldap_user,ldap_pass)
    	dn,attr = conn.search_s(ldap_base,ldap.SCOPE_SUBTREE,'uid=betausersids',['uidNumber'])[0]
    	return attr['uidNumber'][0]

    def save_previous_id(self,id):
    	id_file = open(tmp_file,'w')
    	id_file.write(id)
    	id_file.close()

    def calculate_diff(self):
    	if os.path.exists(tmp_file):
            id_file = open(tmp_file,'r')
            previous_id = id_file.read()
            current_id = self.get_user_id()
            diff = int(current_id)-int(previous_id)
            self.save_previous_id(self.get_user_id())
            return({'registered':diff})
        else:
            self.save_previous_id(self.get_user_id())
            return({'registered':0})

    def run(self):
        return self.calculate_diff()
