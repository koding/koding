class monit::service {
 if $require_deploy {
    service { "monit":
        ensure => running,
        hasstatus => true,
        hasrestart => true,
        enable => true,
        require => [Class["monit::config"],Class["gluster_client"],Class["nodejs_rpm::install"]]
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
