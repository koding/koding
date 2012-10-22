
class hosting_packages::terminal {
    
     $_version = '1.1-2.el6'

    package { lve_exec:
        ensure  => "${_version}",
        require => Class["yumrepos::koding"],
    }
    
}
