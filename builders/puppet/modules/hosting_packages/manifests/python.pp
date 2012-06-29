
class hosting_packages::python {
    
    # modules installed from RPM
    $python_modules = ["pymongo-gridfs",
                        "pymongo",
                        "python27",
                        "python27-devel",
                        "python27-tools",
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
        require => [ Class["yumrepos::epel"], Package["python"], Class["yumrepos::koding"] ],
        notify => Class["cloudlinux::cagefs_update"],
    }
}
