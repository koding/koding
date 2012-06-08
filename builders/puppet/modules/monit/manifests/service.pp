class monit::service {
 if $require_deploy {
    service { "monit":
        ensure => running,
        hasstatus => true,
        hasrestart => true,
        enable => true,
        require => [Class["monit::config"],Class["deploy_from_s3::deploy"]]
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
