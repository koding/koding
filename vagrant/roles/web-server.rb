name "web-server"
description "The  role for WEB servers"

env_run_lists "prod-webstack-a" => ["role[base_server]",
                                    "recipe[nginx]",
                                    "recipe[kd_deploy::nginx_conf]",
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
                                    "recipe[nginx]",
                                    "recipe[kd_deploy::nginx_conf]",
                                    "recipe[zabbix-agent]"
                                   ],
               "_default" => ["role[base_server]",
                                    "recipe[nginx]",
                                    "recipe[nodejs]",
                                    "recipe[golang]",
                                    "recipe[papertrail]",
                                    "recipe[kd_deploy]",
                                    "recipe[kd_deploy::nginx_conf]",
                                   ]


default_attributes({ 
                     "kd_deploy" => {"enabled" => true,
                                     "role" => "web-server"
                                    },
                     "launch" => {
                                "programs" => ["webserver"],
                                "build_client" => true
                     },
                     "log" => {
                                "files" => ["/var/log/upstart/webserver.log",
                                            "/var/log/chef/client.log"
                                           ]       
                     }
})
