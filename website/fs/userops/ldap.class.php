<?php

ini_set('display_errors', 0);

class Ldap {

    /* Example:

    $ldap = new Ldap();
    if ($ldap->createKodingUser('username','Full Name','PlainTextPassword'))
    {
        return true;
    }
    else
    {
        return false;
    }

    */

        private $alert_mail = 'aleksey@koding.com';

        private $ldap_uri  = "ldaps://ldap0.prod.system.aws.koding.com";
        private $ldap_rdn  = "uid=KAdmin,ou=Special Users,dc=koding,dc=com";
        private $ldap_pass = "sOg4:L]iM7!_UV-H";

        private $base_users_dn = "ou=Beta,ou=People,dc=koding,dc=com";
        private $base_group_dn = "ou=Beta,ou=Groups,dc=koding,dc=com";
        private $free_next_id  = "uid=betaUsersIDs,dc=koding,dc=com";
        private $free_group    = "cn=freeusers,ou=Groups,dc=koding,dc=com";

        private $bind;
        private $ds;

        function __construct () {
        // make connection and bind to ldap server
            openlog("[PHP Ldap]",LOG_NDELAY, LOG_LOCAL4);

            $this->ds = ldap_connect($this->ldap_uri) or die ("Could not connect to $ldap_uri");
            if ($this->ds) {
                $this->bind = ldap_bind($this->ds, $this->ldap_rdn, $this->ldap_pass);
                if (!$this->bind) {
                    $err = "[ERROR] Could not bind to ldap server $this->ldap_uri: ".ldap_error($this->ds);
                    mail($this->alert_mail,"useradd error!",$err);
                    syslog(LOG_ERR, $err);
                    die ($err);
                }
            }
        }
        
        private function logger ($message, $priority) {
                //echo ($message."\n");
                if ( $priority == LOG_ERR ) { 
                    echo "yo";
                    mail($this->alert_mail,"useradd error!",$message);
                }
                syslog($priority, $message);
        }

        private function createUser ($username, $fullname, $uid, $password) {
        /* 
            Create posix account

            Parameters:
              $username  # string: username should be lowercase
              $fullname  # string: user's real fill name eg "Bob Marley"
              $uid       # number: user's uniq ID (unix UID)
              $password  # string: plain text password, it will be encrypted by ldap server

            Return Values:
              Returns TRUE on success or FALSE on failure.
        */
            $user_entry['objectClass'][0] = "top";
            $user_entry['objectClass'][1] = "person";
            $user_entry['objectClass'][2] = "organizationalPerson";
            $user_entry['objectClass'][3] = "inetorgperson";
            $user_entry['objectClass'][4] = "posixAccount";
            $user_entry['cn'] = $username;
            $user_entry['loginShell'] = "/bin/bash";
            $user_entry['uidNumber'] = $uid;
            $user_entry['gidNumber'] = $uid;
            $user_entry['givenName'] = $username;
            $user_entry['sn'] = $username;
            $user_entry['uid'] = $username;
            $user_entry['gecos'] = $fullname;
            $user_entry['homeDirectory'] = "/Users/${username}";
            $user_entry['userPassword'] = $password;
            
            if (!ldap_add($this->ds,"uid=${username},$this->base_users_dn",$user_entry)) {
                $this->logger("[ERROR] Could not add user $username to ldap in $this->base_users_dn: ".ldap_error($this->ds), LOG_ERR);
                return false;
            }
            $this->logger("[OK] User $username added to ldap in $this->base_users_dn", LOG_INFO);
            return true;
        }

        private function createGroup ($groupname, $gid) {
         /* 
            Create posix group

            Parameters:
              $groupname # string: groupname should be lowercase and the same with $username
              $gid       # number: group's uniq ID (unix GID), should be the same with $uid

            Return Values:
              Returns TRUE on success or FALSE on failure.
        */
            $group_entry['objectClass'][0] = "top";
            $group_entry['objectClass'][1] = "posixgroup";
            $group_entry['objectClass'][2] = "groupofuniquenames";
            $group_entry['gidNumber'] = $gid;
            $group_entry['cn'] = $groupname;

            if (!ldap_add($this->ds,"cn=${groupname},$this->base_group_dn",$group_entry)) {
                $this->logger("[ERROR] Could not add group $groupname to ldap in $this->base_group_dn: ".ldap_error($this->ds), LOG_ERR);
                return false;
            }
            $this->logger("[OK] Group $groupname added to ldap in $this->base_group_dn", LOG_INFO);
            return true;
        }

        private function updateFreeID($id) {
         /* 
            Increment UID which is used for user's UID/GID

            Parameters:
              $id   # number: previous ID

            Return Values:
              Returns TRUE on success or FALSE on failure.
        */

            $entry["uidnumber"] = ++$id;
            if (!ldap_modify($this->ds, $this->free_next_id, $entry)) {
                $this->logger("[ERROR] Could not increment uid number in $this->free_next_id: ".ldap_error($this->ds), LOG_ERR);
                return false;
            }
            $this->logger("[OK] uid number in $this->free_next_id incremented , new value is ${entry["uidnumber"]}", LOG_INFO);
            return true;
        }


        private function findFreeID () {
         /* 
            Find next free ID for user's UID/GID, returned value will be usered for createGroup and createUser
            and will be incremented by updateFreeID method

            Parameters:
              ...

            Return Values:
              Returns free ID on success or FALSE on failure.
        */
            $filter = "(uid=*)";
            $search = ldap_search($this->ds, $this->free_next_id, $filter);
            if (!$search) {
                $this->logger("[ERROR] Could not find record $this->free_next_id: ".ldap_error($this->ds), LOG_ERR);
                return false;
            } else {
                $entry  = ldap_first_entry($this->ds, $search);
                $result = ldap_get_values($this->ds, $entry, "uidnumber");
                if (!$result) {
                    $this->logger("[ERROR] Could not free ID for UID/GID in $this->free_next_id: ".ldap_error($this->ds), LOG_ERR);
                    return false;
                } else {
                    if (!$this->updateFreeID($result[0])) {
                        $this->logger("[ERROR] free ID wasnt incremented/updated ,we cant return free ID . please fix this first", LOG_ERR);
                        return false;
                    } else {
                        $this->logger("[OK] free ID for UID/GID is ${result[0]}", LOG_INFO);
                        return $result[0];
                    }
                }
            }
        }

        private function addUserToFreeUsersGroup($username) {
        /*
            Add user to special group "freeusers", this group defined in the /etc/security/limits.conf on hosting servers

            Parameters:
                $username  # string: username should be lowercase

            Return Values:
                Returns free ID on success or FALSE on failure.
        */

            $free_group_entry['memberUid'] = $username;

            if (!ldap_mod_add($this->ds, $this->free_group, $free_group_entry)) {
                $this->logger("[ERROR] Could not add user to group $this->free_group: ".ldap_error($this->ds), LOG_ERR);
                return false;
            }
            $this->logger("[OK] User added to group $this->free_group", LOG_INFO);
            return true;
        }

        public function createKodingUser($username,$fullname,$password) {

         /*
            This method will create user,group for user, add user to special free group and so on
            it will make fully functional Koding user for shared hosting servers

            Parameters:
                $username  # string: username should be lowercase
                $fullname  # string: user's real fill name eg "Bob Marley"
                $password  # string: plain text password, it will be encrypted by ldap server

            Return Values:
                Returns TRUE on success or FALSE on failure.
        */
 
            $uid = $this->findFreeID();
            if (!$uid) {
                return false;
            } else {
                $gid = $uid;
                if (!$this->createGroup($username, $gid)) {
                    return false;
                } else {
                    if (!$this->createUser($username, $fullname, $uid, $password)) {
                        return false;
                    }
                    else {
                        if (!$this->addUserToFreeUsersGroup($username)) {
                            return false;
                        }
                    }
                }
            }
            return true;
        }

        function __destruct() {
            closelog();
            ldap_close($this->ds);
        }
           
        
    }// end of Ldap class


$ldap = new Ldap();
$ldap->createKodingUser('username100','Full Name','PlainTextPassword');

