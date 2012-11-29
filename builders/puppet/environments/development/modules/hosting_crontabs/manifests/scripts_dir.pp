class hosting_crontabs::scripts_dir {

    file { "/opt/cronscripts/":
         ensure  => directory,
    }

}
