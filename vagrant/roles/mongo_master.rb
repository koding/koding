name "mongo_master"
description "The role for MongoDB system master servers"

run_list ["recipe[mongodb]"]

default_attributes({ "mongodb" => {
                                "master" => true,
                                "version" => "2.2.2",
                                "data_device" => "/dev/vg0/fs_mongo_data",
                                "log_device"  => "/dev/vg1/fs_mongo_log",
                                "rest" => true,
                                "dbpath" => "/var/lib/mongodb",
                                "logpath" => "/var/log/mongodb",
                                }
                  })
