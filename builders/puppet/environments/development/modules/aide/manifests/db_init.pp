#
#
class aide::db_init {
    
    exec { "db_init":
        command => "/usr/sbin/aide --init && mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz",
        timeout => 0,
        onlyif => "/usr/bin/test ! -e /var/lib/aide/aide.db.gz",
        require => Class["aide::config"],
    }
    
}
