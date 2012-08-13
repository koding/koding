class yumrepos::erlang {
    
    yumrepo { "erlang":
        baseurl => 'http://repos.fedorapeople.org/repos/peter/erlang/epel-$releasever/$basearch/',
        descr => "erlang repo",
        enabled => "1",
        gpgcheck => "0",
    }
}
