class hosting_packages::mounters {
    
    $mounters  = ["fuse-sshfs","fuse-curlftpfs"]
    
    
    package { $mounters:
        ensure => installed,
        require => [Class["yumrepos::koding"], Class["yumrepos::epel"]]
    }
}
