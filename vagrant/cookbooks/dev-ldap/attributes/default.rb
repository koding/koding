default['dev-ldap']['admin_account'] = 'cn=directory manager' 
default['dev-ldap']['admin_pass'] = 'Secret123'
default['dev-ldap']['suffix'] = 'dc=koding,dc=com'
default['dev-ldap']['host'] = '10.5.5.5'

default['dev-ldap']['indexes'] = [ "gidnumber:eq", "memberUid:eq", "uidNumber:eq"]
