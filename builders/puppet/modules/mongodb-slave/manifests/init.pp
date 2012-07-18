# Class: mongodb
#
#
class mongodb-slave {
    include mongodb-slave::mongorepo,mongodb-slave::install,mongodb-slave::service,mongodb-slave::config
}
