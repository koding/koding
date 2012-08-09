define bind_dir ($device,$mpoint) {

    file { "$mpoint":
        ensure => 'directory',
    }

    mount {"$mpoint":
        atboot  => true,
        ensure  => mounted,
        fstype  => "none",
        device  => "$device",
        name    => "$mpoint",
        options => "defaults,bind",
        target  => '/etc/fstab',
        require => [File[$mpoint],Class['gluster_client::mount']],
    }


}

