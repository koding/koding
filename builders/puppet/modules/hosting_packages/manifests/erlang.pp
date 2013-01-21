# Class: hosting_packages::ruby
#
#
class hosting_packages::erlang {
    
    $erlang  = ["esl-erlang"]
    
    
    package { $erlang:
        ensure => installed,
        require => Class["yumrepos::erlang"],
        notify => Class["cloudlinux::cagefs_update"]
    }
}
