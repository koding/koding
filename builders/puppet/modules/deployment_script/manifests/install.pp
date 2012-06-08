# Class: install
#
#
class deployment_script::install {
    
    $git_revision = '98c8d3bd8eb7249aa6920a4e8e77f5bef17a1375'
    
    exec { "install_requests":
        command => "/usr/bin/easy_install requests",
        refreshonly => true,
    }
    exec { "install_argparse":
        command => "/usr/bin/easy_install argparse",
        refreshonly => true,
    }
    
    file { "deployment_script":
        ensure => file,
        path   => '/tmp/deploy.py',
        source => "puppet:///modules/deployment_script/deploy.py",
        owner  => 'root',
        group  => 'root',
        mode   => '0700',

        notify => Exec["run_deployment"],
    }
    
    exec { "run_deployment":
        command => "/tmp/deploy.py -r kfmjs -b privateBeta -e production -s $(hostname) -g $git_revision  --initial",
        refreshonly => true,
        timeout => 0,
        onlyif  => "/usr/bin/test ! -e /opt/kfmjs/.revision",
        require => User["node"]
    }
       
}