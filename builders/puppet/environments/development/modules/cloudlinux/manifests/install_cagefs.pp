# Class: cloudlinux::install_cagefs
#
#
class cloudlinux::install_cagefs {

    exec { "init":
        command => "/usr/sbin/cagefsctl --init",
        timeout => 0,
        refreshonly => true,
        onlyif => "/usr/bin/test ! -d /usr/share/cagefs-skeleton/"
    }
    exec { "enable":
        command => "/usr/sbin/cagefsctl --enable-all",
        require => Package["cagefs"],
        onlyif => "/usr/sbin/cagefsctl --display-user-mode | /bin/grep 'Disable All'"
    }
}
