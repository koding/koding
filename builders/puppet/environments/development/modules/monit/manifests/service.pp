class monit::service {
    service { "monit":
        ensure => running,
        hasstatus => true,
        hasrestart => true,
        enable => true,
        #require => [Class["monit::config"],Class["gluster_client"],Class["nodejs_rpm::install"]]
        #require => [Class["monit::config"],Class["nodejs_rpm::install"]]
        require => [Class["monit::config"]]
    }

}
