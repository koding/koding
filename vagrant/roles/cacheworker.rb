name "cacheworker"
description "The  role for cacheworker servers"

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
                                     "role" => "cacheworker"},
                     "launch" => {
                                "programs" => ["cacheWorker"]
                     },
                     "log" => {
                                "files" => ["/var/log/upstart/cacheWorker.log",
                                            "/var/log/chef/client.log"
                                           ]
                     }
                     
})
