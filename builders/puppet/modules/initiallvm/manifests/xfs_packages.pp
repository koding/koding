class initiallvm::xfs_packages {
    package { ["xfsdump.x86_64","xfsprogs.x86_64"]:
        ensure => present,
    }
}
