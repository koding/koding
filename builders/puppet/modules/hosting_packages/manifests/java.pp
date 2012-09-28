
class hosting_packages::java {
    
    
    package { ["java-1.6.0-sun","java-1.6.0-sun-devel"]:
        ensure => installed,
        notify => Class["cloudlinux::cagefs_update"]

    }
    
}
