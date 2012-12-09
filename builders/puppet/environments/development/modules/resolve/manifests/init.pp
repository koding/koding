define resolve($nameserver1, $nameserver2, $domain, $search) {
    $str = "search $search\ndomain $domain\nnameserver $nameserver1\nnameserver $nameserver2\n"

    file { "/etc/resolv.conf":
      content => $str,
      owner => 'root',
      group => 'root',
      mode => '0644',
    }
}
