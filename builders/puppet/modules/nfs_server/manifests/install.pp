class nfs_server::install {

    package { ["nfs-utils", "nfs-utils-lib"]:
        ensure => installed,
    }
}

