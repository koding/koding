
class hosting_packages::terminal {
    
    $version = '1.1' 
    package { lve_exec-$version:
        ensure  => installed,
        require => Class["yumrepos::koding"],
    }
    
}
