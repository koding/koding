name "authworker"
description "The  role for authWorker servers"

run_list ["role[base_server]","recipe[nodejs]","recipe[golang]", "recipe[supervisord]","recipe[papertrail]","recipe[kd_deploy]"]

default_attributes({ 
                     "launch" => {
                                "programs" => ["authWorker"]
                     },
                     "log" => {
                                "files" => ["/var/log/authWorker.log"]       
                     }

})
