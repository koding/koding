class hosting_packages::python {
    
    # modules installed from RPM
    $python_modules = ["pymongo-gridfs",
                        "pymongo",
                        "python27-devel",
                        "python27-tools",
                        "MySQL-python",
                        "ipython",
         		        "python-flup.noarch",
                        "python-virtualenv",
                        "python-setuptools",
                        "python-docutils",
                      ]
    
    package { ["python","python27"]:
        ensure => installed,
        require => Class["yumrepos::koding"],
    }

    exec { "pip":
        command => '/usr/bin/easy_install pip',
        unless => "/usr/bin/which pip",
    }
    
    exec {"django":
    	command=> "/usr/bin/pip install django",
	    unless => '/usr/bin/test -d /usr/lib/python2.6/site-packages/django',
        require => [Package["python"],Exec['pip']],
        notify => Class["cloudlinux::cagefs_update"],
    }

    #package { $django:
    #    ensure => installed,
    #    provider => pip,
    #    require => [Package["python"],Exec['pip'],Exec["test_django"]],
    #    notify => Class["cloudlinux::cagefs_update"],
    #}

    package { $python_modules:
        ensure => installed,
        require => [ Class["yumrepos::epel"], Package["python"], Class["yumrepos::koding"]],
        notify => Class["cloudlinux::cagefs_update"],
    }
}
