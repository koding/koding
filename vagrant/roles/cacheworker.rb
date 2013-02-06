name "cacheworker"
description "The  role for cacheworker servers"

run_list ["role[base_server]","recipe[nodejs]","recipe[golang]", "recipe[supervisord]","recipe[kd_deploy]"]

default_attributes({ 
                     "launch" => {
                                "programs" => ["cacheWorker"]
                     }
})
