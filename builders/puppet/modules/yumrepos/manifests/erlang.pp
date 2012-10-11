class yumrepos::erlang {
    
    yumrepo { "erlang":
        baseurl => 'http://binaries.erlang-solutions.com/rpm/centos/$releasever/$basearch',
        descr => "erlang repo",
        enabled => "1",
        gpgcheck => "0",
    }
}
