name "guestcleanup"
description "The  role for guestcleanup servers"

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
                                     "role" => "guestcleanup"},
                     "launch" => {
                                "programs" => ["guestCleanup"]
                     },
                     "log" => {
                                "files" => ["/var/log/upstart/guestCleanup.log",
                                            "/var/log/chef/client.log"
                                           ]       
                     }

})
