
class hosting_packages::terminal {
    
     $_version = '1.1'

    package { lve_exec:
        ensure  => "${_version}",
        require => Class["yumrepos::koding"],
    }
    
}
