
class hosting_packages::python {
    
    # modules installed from RPM
    $python_modules = ["pymongo-gridfs",
                        "pymongo",
                        "MySQL-python",
                        "ipython",
         		        "python-flup.noarch",
                        "python-virtualenv",
                        "python-setuptools"
                      ]
    
    package { "python":
        ensure => installed,
    }
    
    package { $python_modules:
        ensure => installed,
        require => [ Class["yumrepos::epel"], Package["python"] ],
        notify => Class["cloudlinux::cagefs_update"],
    }
}
