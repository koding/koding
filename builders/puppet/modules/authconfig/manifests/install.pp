#
#
class authconfig::install {
    
    package { ["sssd","pam_ldap","sssd-tools"]:
        ensure => installed,
    }
}
