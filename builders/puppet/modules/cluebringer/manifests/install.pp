# Class: name
#
#
class cluebringer::install {
    
    $package = "cluebringer-2.0.11-1.noarch.rpm"
    $dependencies = ["perl-Net-DNS",
                     "perl-Net-Server",
                     "perl-Mail-SPF",
                     "perl-Cache-Cache",
                     "perl-Cache-FastMmap",
                     "perl-Config-IniFiles",
                     "perl-Net-CIDR",
                     "perl-DBI"]
    
    package { $dependencies:
        ensure => installed,
        require => Class["yumrepos::epel"]
    }
    
    file { "/tmp/${package}":
        ensure => file,
        source => "puppet:///modules/cluebringer/${package}",
        owner  => "root",
        group  => "root",
        replace => "no",
    }
    
    package { "cluebringer":
        ensure => installed,
        source => "/tmp/${package}",
        provider => "rpm",
        require => [File["/tmp/${package}"],Package[$dependencies]],
        notify => Exec["install_db"]
    }
    
    file { "cluebringer_db":
        ensure => file,
        source => "puppet:///modules/cluebringer/policyd.mysql.sql",
        path => "/tmp/policyd.mysql.sql",
        owner => "root",
        group => "root",
    }
    
    exec { "install_db":
        command => "/usr/bin/mysql -Dcluebringer -ucluebringer -phurh-sha-thax < /tmp/policyd.mysql.sql",
        refreshonly => true,
        require => [Package["cluebringer"],File["cluebringer_db"]]
    }
}