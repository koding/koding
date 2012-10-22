class yumrepos::koding {
    
    yumrepo { "koding":
        baseurl => "http://yum.prod.system.aws.koding.com/koding/",
        descr => "Koding repo",
        enabled => "1",
        gpgcheck => "0",
        priority => 1,
        require => Package["yum-plugin-priorities"],
    }
}
