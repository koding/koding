class nginx_fm::repo {
    yumrepo { "nginx_fm":
        baseurl  =>'http://nginx.org/packages/centos/6/$basearch/',
        descr    => "Nginx repository",
        enabled  => "1",
        gpgcheck => "0",
    }
}
