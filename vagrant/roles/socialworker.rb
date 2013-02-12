name "socialworker"
description "The  role for socialWorker servers"

run_list ["role[base_server]","recipe[nodejs]","recipe[golang]", "recipe[supervisord]","recipe[papertrail]","recipe[kd_deploy]"]

default_attributes({ 
                     "launch" => {
                                "programs" => ["socialWorker"]
                     },
                     "log" => {
                                "files" => ["/var/log/socialWorker.log"]       
                     }

})
