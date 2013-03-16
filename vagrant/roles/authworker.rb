name "authworker"
description "The  role for authWorker servers"

env_run_lists "prod-webstack-a" => ["role[base_server]",
                                    "recipe[nodejs]",
                                    "recipe[golang]",
                                    "recipe[papertrail]",
                                    "recipe[kd_deploy]",
                                    "recipe[zabbix-agent]"
                                   ],
              "prod-webstack-b" => ["role[base_server]",
                                    "recipe[nodejs]",
                                    "recipe[golang]",
                                    "recipe[papertrail]",
                                    "recipe[kd_deploy]",
                                    "recipe[zabbix-agent]"
                                   ],
               "_default" => ["role[base_server]",
                                    "recipe[nodejs]",
                                    "recipe[golang]",
                                    "recipe[papertrail]",
                                    "recipe[kd_deploy]",
                                   ]



default_attributes({ 
                     "kd_deploy" => {"enabled" => true,
                                     "role" => "authworker" },
                     "launch" => {
                                "programs" => ["authWorker"]
                     },
                     "log" => {
                                "files" => ["/var/log/upstart/authWorker.log",
                                            "/var/log/chef/client.log"
                                           ]
                     }

})
