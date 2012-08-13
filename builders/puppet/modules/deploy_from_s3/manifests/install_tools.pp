# Class: deploy_from_s3::install_script
#
#
class deploy_from_s3::install_tools {
    
    package { "s3cmd":
        ensure => installed,
        require => Class["deploy_from_s3::yumrepo"]
    }
    
    file { "/root/.s3cfg":
        ensure => file,
        source => "puppet:///modules/deploy_from_s3/s3cfg",
        owner => 'root',
        group => 'root',
        mode => '0600',
    }
}