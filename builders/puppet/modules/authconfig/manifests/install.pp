#
#
class authconfig::install {
    
    package { ["sssd","pam_ldap"]:
        ensure => installed,
    }
}
