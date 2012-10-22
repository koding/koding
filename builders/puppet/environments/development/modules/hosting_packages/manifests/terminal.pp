
class hosting_packages::terminal {
    
     $_version = '1.1'

    package { lve_exec:
        ensure  => "lve_exec-${_version}",
        require => Class["yumrepos::koding"],
    }
    
}
