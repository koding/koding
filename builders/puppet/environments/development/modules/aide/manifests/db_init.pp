#
#
class aide::db_init {
    
    exec { "db_init":
        command => "/usr/sbin/aide --init && mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz",
        onlyif => "/usr/bin/test ! -e /var/lib/aide/aide.db.gz",
        require => Class["aide::config"],
    }
    
}
