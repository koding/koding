# Class: deploy_from_s3::exec_script
#
#
class deploy_from_s3::deploy {
    $kfmjs_version = '/usr/bin/GET http://169.254.169.254/latest/user-data| /bin/cut -d: -f2'
    $cmd = "/usr/bin/s3cmd --force get s3://koding-updater/kfmjs-$($kfmjs_version).tar.gz /tmp/kfmjs.tar.gz"

    exec { "download":
        #command => "/usr/bin/s3cmd --force get s3://koding-updater/kfmjs.tar.gz /tmp/kfmjs.tar.gz",
        command => $cmd,
        timeout => 0,
        onlyif  => "/usr/bin/test ! -e /opt/kfmjs/.revision",
        require => Class["deploy_from_s3::install_tools"],
        notify => Exec["deploy"],
        logoutput => "on_failure",
    }
    exec { "deploy":
        command => "/bin/tar xzf /tmp/kfmjs.tar.gz -C /opt/",
        refreshonly => true,
        user => "node",
        group => "node",
        require => User["node"],
        logoutput => "on_failure",
    }
    # file { "/opt/kfmjs/.revision":
    #     ensure => file,
    #     owner  => "node",
    #     group => "node",
    #     replace=>"no", # Only add a file if it’s absent
    #     require => Exec["deploy"]
    # }
}
