class initiallvm::mount {

    mount {"mount_usersfs":
        atboot  => true,
        ensure  => mounted,
        fstype  => "xfs",
        device  => "/dev/vg0/fs_users",
        name    => "/Users",
        options => "defaults,noatime,nosuid,uquota",
        remounts => true,
        target  => '/etc/fstab',
        require  => [Class["initiallvm::create_fs"],File["Users"]]
    }

}
                                                                                                                                                                    