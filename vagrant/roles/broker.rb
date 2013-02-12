name "broker"
description "The  role for Broker servers"

env_run_lists "prod-webstack-a" => ["role[base_server]",
                                    "recipe[nodejs]",
                                    "recipe[golang]",
                                    "recipe[supervisord]",
                                    "recipe[papertrail]",
                                    "recipe[kd_deploy]"
                                   ],
              "prod-webstack-b" => ["role[base_server]",
                                    "recipe[nodejs]",
                                    "recipe[golang]",
                                    "recipe[papertrail]",
                                    "recipe[kd_deploy]",
                                   ],
               "_default" => ["role[base_server]",
                                    "recipe[nodejs]",
                                    "recipe[golang]",
                                    "recipe[papertrail]",
                                    "recipe[kd_deploy]",
                                   ]



default_attributes({
                     "launch" => {
                                "programs" => ["goBroker"]
                     },
                     "log" => {
                                "files" => ["/var/log/goBroker.log"]       
                     }

})
