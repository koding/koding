name "emailworker"
description "The  role for emailWorker servers"

run_list ["role[base_server]","recipe[nodejs]","recipe[golang]", "recipe[supervisord]","recipe[papertrail]","recipe[kd_deploy]"]

default_attributes({ 
                     "launch" => {
                                "programs" => ["emailWorker"]
                     },
                     "log" => {
                                "files" => ["/var/log/emailWorker.log"]       
                     }

})
