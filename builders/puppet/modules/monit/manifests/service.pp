class monit::service {
 if $require_deploy {
    service { "monit":
        ensure => running,
        hasstatus => true,
        hasrestart => true,
        enable => true,
        require => [Class["monit::config"],Class["gluster_client"]]
    }
 }else{
     service { "monit":
         ensure => running,
         hasstatus => true,
         hasrestart => true,
         enable => true,
         require => Class["monit::config"],
     }
 }

}
