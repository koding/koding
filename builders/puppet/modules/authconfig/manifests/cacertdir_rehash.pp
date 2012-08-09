#
#
class authconfig::cacertdir_rehash {
    
    exec { "cacertdir_rehash":
        command => "/usr/sbin/cacertdir_rehash /etc/openldap/cacerts",
        refreshonly => true,
    }
    
}
