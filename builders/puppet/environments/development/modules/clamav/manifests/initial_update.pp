class clamav::initial_update {
    exec { "initial_update": 
        command => "/usr/bin/freshclam --quiet",
        refreshonly => true,
        subscribe => Class["clamav::install"],
        timeout => 0,
    }
}
