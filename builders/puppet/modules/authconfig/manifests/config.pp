#
#
class authconfig::config {

    File {
        ensure => present,
        owner  => 'root',
        group  => 'root',
        require => Class["authconfig::install"],
        notify  => Class["authconfig::service"],
    }

    file { "/etc/sysconfig/authconfig":
        source  => "puppet:///modules/authconfig/authconfig",
    }

    #file { "/etc/pam.d/fingerprint-auth-ac":
    #    source => 'puppet:///modules/authconfig/fingerprint-authc-ac',
    #}

   file { "/etc/pam.d/password-auth-ac":
        source => 'puppet:///modules/authconfig/password-auth-ac',
    }

   file { "/etc/pam.d/smartcard-auth-ac":
        source => 'puppet:///modules/authconfig/smartcard-auth-ac',
    }

   file { "/etc/pam.d/system-auth-ac":
        source => 'puppet:///modules/authconfig/system-auth-ac',
    }

    file { "/etc/libuser.conf":
        source => 'puppet:///modules/authconfig/libuser.conf',
    }

    file { "/etc/nsswitch.conf":
        source => 'puppet:///modules/authconfig/nsswitch.conf',
    }

    file { "/etc/openldap/ldap.conf":
        source => 'puppet:///modules/authconfig/openldap.conf',
    }

    file { "/etc/pam_ldap.conf":
        source => 'puppet:///modules/authconfig/pam_ldap.conf',
    }

    file { "/etc/sssd/sssd.conf":
        mode => 0600,
        source => 'puppet:///modules/authconfig/sssd.conf',
    }

    file { "/etc/openldap/cacerts":
        ensure => directory,
    }

    file { "/etc/openldap/cacerts/admin.crt":
        source => 'puppet:///modules/authconfig/cacerts/admin.crt',
        require => File["/etc/openldap/cacerts"],
        notify => Exec["cacertdir_rehash"],
    }

    file { "/etc/openldap/cacerts/admin.csr":
        source => 'puppet:///modules/authconfig/cacerts/admin.crt',
        require => File["/etc/openldap/cacerts"],
        notify => [Exec["cacertdir_rehash"],Class["authconfig::service"]]
    }

    file { "/etc/openldap/cacerts/koding-ca.crt":
        source => 'puppet:///modules/authconfig/cacerts/koding-ca.crt',
        require => File["/etc/openldap/cacerts"],
        notify => [Exec["cacertdir_rehash"],Class["authconfig::service"]]
    }





}
