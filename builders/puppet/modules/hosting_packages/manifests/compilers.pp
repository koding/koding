#
#
class hosting_packages::editors {
    
    $editors  = ["vim-minimal", "emacs", "emacs-git" ]
    
    
    package { $editors:
        ensure => installed,
        require => Class["yumrepos::epel"],
        notify => Class["cloudlinux::cagefs_update"]
    }
}
