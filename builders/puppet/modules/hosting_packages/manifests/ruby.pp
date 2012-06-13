# Class: hosting_packages::ruby
#
#
class hosting_packages::ruby {
    
    # modules installed from RPM
    $ruby_modules = ["ruby-mysql","ruby-sqlite3" ]
    
    package { "ruby":
        ensure => installed,
    }
    
    package { $ruby_modules:
        ensure => installed,
        require => [ Class["yumrepos::epel"], Package["ruby"] ],
        notify => Class["cloudlinux::cagefs_update"]
    }
}
