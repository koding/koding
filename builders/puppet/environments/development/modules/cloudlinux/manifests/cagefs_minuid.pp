#
#
class cloudlinux::cagefs_minuid {

    exec { "minuid":
        command => "/usr/sbin/cagefsctl --set-min-uid  1000",
        timeout => 0,
        onlyif => "/usr/bin/test ! -e /etc/cagefs/cagefs.min.uid"
    }
}

