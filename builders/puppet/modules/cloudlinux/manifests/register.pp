# Class: cloudlinux::
#
#
class cloudlinux::register {
    
    exec { "register_cl":
        command => "/usr/sbin/rhnreg_ks --activationkey 4555-b4507cea4885d1d0df2edf70ee0d52da",
        timeout => 0,
        onlyif => "/usr/bin/test ! -e /etc/sysconfig/rhn/systemid"
    }
    
}
