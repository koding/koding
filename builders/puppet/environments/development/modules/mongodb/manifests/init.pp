# Class: mongodb
#
#
class mongodb {
    include mongodb::mongorepo,mongodb::install,mongodb::service,mongodb::config
}