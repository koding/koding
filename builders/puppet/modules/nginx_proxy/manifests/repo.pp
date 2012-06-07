class nginx_proxy::repo {
    yumrepo { "nginx_proxy":
        baseurl  =>'http://nginx.org/packages/centos/6/$basearch/',
        descr    => "Nginx repository",
        enabled  => "1",
        gpgcheck => "0",
    }
}
