class admin_nginx::repo {
    yumrepo { "admin_nginx":
        baseurl  =>'http://nginx.org/packages/rhel/6/$basearch/',
        descr    => "Nginx RHEL repository",
        enabled  => "1",
        gpgcheck => "0",
    }
}
