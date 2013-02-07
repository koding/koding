default['mongodb']['version']   = '2.0.8'
default['mongodb']['package_name'] = 'mongodb20-10gen'
default['mongodb']['service_name'] = "mongodb"
default['mongodb']['configfile'] = "/etc/mongodb.conf"


# default configuration
default['mongodb']['dbpath']  = '/var/lib/mongodb'
default['mongodb']['logpath'] = '/var/log/mongodb'
default['mongodb']['port']    = '27017'
default['mongodb']['journal'] = true
default['mongodb']['rest']    = false
default['mongodb']['quiet']   = true
default['mongodb']['httpinterface']   = true


# replocation
default['mongodb']['master']    = false
default['mongodb']['oplogsize'] = false

default['mongodb']['slave']  = false
default['mongodb']['source'] = false


# system
default['mongodb']['data_device'] = '/dev/vg0/fs_mongo_data'
default['mongodb']['log_device']  = '/dev/vg1/fs_mongo_log'
