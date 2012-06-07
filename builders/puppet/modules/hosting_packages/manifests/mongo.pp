
class hosting_packages::mongo {

    yumrepo { "mongo":
        baseurl =>'http://downloads-distro.mongodb.org/repo/redhat/os/x86_64',
        descr => "10gen Repository",
        enabled => "1",
        gpgcheck => "0",
    }

    
    $mongo = ["mongo-10gen.x86_64"]
    
    package { $mongo:
        ensure  => installed,
        notify => Class["cloudlinux::cagefs_update"]
    }
    
}
