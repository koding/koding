class static_nginx::repo {
    yumrepo { "static_nginx":
        baseurl  =>'http://nginx.org/packages/centos/6/$basearch/',
        descr    => "nginx repository",
        enabled  => "1",
        gpgcheck => "0",
    }
}
