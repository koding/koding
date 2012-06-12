# Class: cloudlinux::pam_lve
#
#
class cloudlinux::pam_lve {
    package { "pam_lve":
        ensure => installed,
    }
    
    File {
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    
    file { "/etc/pam.d/su":
        ensure => file,
        source => "puppet:///modules/cloudlinux/etc/pam.d/su",
        require => Package['pam_lve']
    }
    
    file { "/etc/pam.d/sshd":
         ensure => file,
         source => "puppet:///modules/cloudlinux/etc/pam.d/sshd",
         require => Package['pam_lve']
     }
     
     file { "/etc/pam.d/crond":
          ensure => file,
          source => "puppet:///modules/cloudlinux/etc/pam.d/crond",
          require => Package['pam_lve']
      }


}
