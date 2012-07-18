# Class: mongodb::install
#
#
class mongodb-slave::install {
    
    
    package { "mongo-10gen-server":
        ensure => installed,
        require => Class["mongodb-slave::mongorepo"],
    }
        
    package { "mongo-10gen":
        ensure => $version,
        require => Class["mongodb-slave::mongorepo"]
    }
    


}
