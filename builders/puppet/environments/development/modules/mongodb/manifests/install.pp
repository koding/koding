# Class: mongodb::install
#
#
class mongodb::install {
    
    
    package { "mongo-10gen-server":
        ensure => installed,
        #require => [Class["dblvm"],Class["mongodb::mongorepo"]]
        require => Class["mongodb::mongorepo"]
    }
        
    package { "mongo-10gen":
        ensure => $version,
        require => Class["mongodb::mongorepo"]
    }
    


}
