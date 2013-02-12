name "broker"
description "The  role for Broker servers"

run_list ["role[base_server]","recipe[nodejs]","recipe[golang]", "recipe[supervisord]","recipe[papertrail]","recipe[kd_deploy]"]

default_attributes({
                     "launch" => {
                                "programs" => ["goBroker"]
                     },
                     "log" => {
                                "files" => ["/var/log/goBroker.log"]       
                     }

})
