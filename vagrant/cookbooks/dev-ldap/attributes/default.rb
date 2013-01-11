default['dev-ldap']['admin_account'] = 'cn=directory manager' 
default['dev-ldap']['admin_pass'] = 'Secret123'
default['dev-ldap']['suffix'] = 'dc=koding,dc=com'
default['dev-ldap']['host'] = node['ipaddress']
default['dev-ldap']['indexes'] = [ "gidnumber:eq", "memberUid:eq", "uidNumber:eq"]

