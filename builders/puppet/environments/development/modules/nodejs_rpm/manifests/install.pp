# Class: nodejs_rpm::install
#
#
class nodejs_rpm::install {
    

    $coffee_version = '1.3.3'
    
    package { "nodejs":
        ensure => installed,
        alias  => 'nodejs',
        require => Class["yumrepos::koding"],
    }
    
    #file {"/usr/bin/node":
    #     ensure  => symlink,
    #     target  => "/usr/bin/nodejs",
    #     require => Package["nodejs"]
    # }
    
    
    exec { "coffee-script":
        command => "npm -g install coffee-script@${coffee_version}",
        require => Package["nodejs"],
        path    => "/usr/bin:/usr/sbin:/bin:/usr/local/bin",
        user    => "root",
        group   => "root",
        onlyif  => '/usr/bin/test ! -e  /usr/bin/coffee'
    }
}
