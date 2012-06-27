class yumrepos::koding {
    
    yumrepo { "ius":
        baseurl => "http://yum.prod.system.aws.koding.com/koding/",
        descr => "Koding repo",
        enabled => "1",
        gpgcheck => "0",
    }
}
