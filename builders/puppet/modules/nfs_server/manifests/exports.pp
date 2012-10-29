#
#
class nfs_server::exports {

    File { 
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => 0644,
    }

    file { "/etc/exports":
        ensure  => file,
        source  => "puppet:///modules/nfs_server/etc/exports",
        notify => Exec['exportfs'],
    }

    exec { "exportfs":
        command => "/usr/sbin/exportfs -avr",
    }


}

