class aide::config {

    File {
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode => 0600,
        require => Class["aide::install"],
    }

    file { "/etc/aide.conf":
        source  => "puppet:///modules/aide/etc/aide.conf",
    }

}
