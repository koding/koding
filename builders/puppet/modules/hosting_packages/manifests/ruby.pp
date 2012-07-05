# Class: hosting_packages::ruby
#
#
class hosting_packages::ruby {
    
    # modules installed from RPM
    $ruby_modules = ["ruby-mysql","ruby-sqlite3","ruby-devel","ruby19-devel","ruby-irb","ruby19-irb","rubygems","rubygems19" ]
    
    package { ["ruby","ruby19"]:
        ensure => installed,
    }
    
    package { $ruby_modules:
        ensure => installed,
        require => [ Class["yumrepos::epel"], Package["ruby"] , Class["yumrepos::koding"] ],
        notify => Class["cloudlinux::cagefs_update"]
    }
}
