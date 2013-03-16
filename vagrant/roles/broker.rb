name "broker"
description "The  role for Broker servers"

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
                     # kd_deploy enbaled option will be ignored for prod-webstack-b. see kd_deploy::deploy
                     "kd_deploy" => {"enabled" => false,
                                     "role" => "broker"},
                     "launch" => {
                                "programs" => ["goBroker"],
                                "build_gosrc" => true
                     },
                     "log" => {
                                "files" => ["/var/log/upstart/goBroker.log",
                                            "/var/log/chef/client.log"
                                            ]       
                     }

})
