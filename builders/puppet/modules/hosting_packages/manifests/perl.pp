
class hosting_packages::perl {
    
    # modules installed from RPM
    $perl_modules = ["perl-DBD-MySQL",
		     "perl-DBD-SQLite2",
 		     "perl-Test-Simple.x86_64",
		     "perl-devel.x86_64",
		     "perl-ExtUtils-MakeMaker.x86_64",
		     "perl-ExtUtils-ParseXS.x86_64",
		     "perl-Test-Harness.x86_64",
		     "perl-CPAN-Meta-YAML.noarch",
		     "perl-YAML-LibYAML.x86_64",
		     "perl-libwww-perl",
		     "perl-CPAN.x86_64",
		     "perl-FCGI.x86_64",
             "perl-local-lib.noarch",
		    ]
    
    package { "perl":
        ensure => installed,
    }
        
    package { $perl_modules:
        ensure => installed,
        require => [ Class["yumrepos::epel"], Package["perl"] ],
        notify => Class["cloudlinux::cagefs_update"]
    }
}
