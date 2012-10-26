class hosting_crontabs::scripts_dir {

    file { "/opt/cronscripts/":
         ensure  => directory,
         mode => 0700,
         owner => 'root',
         group => 'root',
    }

}
