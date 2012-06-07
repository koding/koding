class nfs_server {

    package { "nfs-utils":
        ensure => installed,
    }
    service { "rpcbind":
        ensure => running,
        enable => true,
    }

    service { [ "nfs", "nfslock" ]:
        ensure => running,
        enable => true,
        require => [Package["nfs-utils"],Service['rpcbind']],
    }
    # nfsuser for ftp

    group { "nfsuser":
        gid => '400',
    }
    user { "nfsuser":
        ensure => present,
        comment => "User for ftp mount",
        home    => "/home/nfsuser",
        managehome => 'true',
        shell => '/bin/sh',
        uid => '400',
        gid => '400',
        require => Group['nfsuser'],
    }
    ssh_authorized_key { "nfsuser":
        ensure => present,
        key    => "AAAAB3NzaC1yc2EAAAABIwAAAQEAuc9OcPPbJ923dAWHoMxN1HA1A65IpRt2D4ZNLzbf/S0upnlQBcR7Bo2eVabFDqoHspqk/C1KwLfwHXhiVv9WFMvAUvmbOTEc1EZR18fn02VSSlodD1DnlATOVnkURfFB7RD7vspfuwqvnO9z868OMe+EZI3i15uYMrrre0DTotEvFUFRX7TAqudVJEXHTa3hg/Sbc54tinh6SY31DLsTImgcpizZ5EGLL6iK8LWnwoMCjo3cjWmatcD+Xp6WVun7k9n22EdCBLgOVF15iAYpxuuCCBGRF+20fHhY5S4cCKFdu3ARZNRqJ5VmgrlmYUWKJs42OoZRy1chrKnPquVYIw==",
        type   => "ssh-rsa",
        user   => "nfsuser",
    }
    # end of nfs user 

}

