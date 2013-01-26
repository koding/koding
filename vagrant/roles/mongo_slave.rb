name "mongo_slave"
description "The role for MongoDB system slave servers"

env_run_lists "prod" =>  ["recipe[mongodb]"],
              "_default" => []

default_attributes({ "mongodb" => {
                                "slave" => true,
                                "source" => "sysdb0.prod.system.aws.koding.com",
                                "version" => "2.2.2",
                                "data_device" => "/dev/vg0/fs_mongo_data",
                                "log_device"  => "/dev/vg1/fs_mongo_log",
                                "rest" => true,
                                "dbpath" => "/var/lib/mongodb",
                                "logpath" => "/var/log/mongodb",
                                "admin_user" => 'admin',
                                "repl_user" => 'repl',
                                "admin_pass" => 'cQ7zD43NvLypgGre',
                                "repl_pass" => 'cQdklsdk3e',
                                }
                  })
