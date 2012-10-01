class pure-ftpd::authapp {
    $app_dir = "/opt/authapp"
    $mongo_auth  = "$app_dir/mongoAuth.py"

    File {
        owner => root,
        group => root,
    }

    package { "pymongo":
        ensure  => installed,
        require => Class["yumrepos::epel"]
    }

    file {
        $app_dir:
            ensure => directory,
            mode => 0700;

        $mongo_auth:
            mode => 0755,
            source => "puppet:///modules/pure-ftpd/$mongo_auth";
    }

}
