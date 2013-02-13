name "web-server"
description "The  role for WEB servers"

env_run_lists "prod-webstack-a" => ["role[base_server]",
                                    "recipe[nginx]",
                                    "recipe[kd_deploy::nginx_conf]",
                                    "recipe[nodejs]",
                                    "recipe[golang]",
                                    "recipe[supervisord]",
                                    "recipe[papertrail]",
                                    "recipe[kd_deploy]"
                                   ],
              "prod-webstack-b" => ["role[base_server]",
                                    "recipe[nginx]",
                                    "recipe[kd_deploy::nginx_conf]",
                                    "recipe[nodejs]",
                                    "recipe[golang]",
                                    "recipe[papertrail]",
                                    "recipe[kd_deploy]",
                                   ],
               "_default" => ["role[base_server]",
                                    "recipe[nginx]",
                                    "recipe[kd_deploy::nginx_conf]",
                                    "recipe[nodejs]",
                                    "recipe[golang]",
                                    "recipe[papertrail]",
                                    "recipe[kd_deploy]",
                                   ]


default_attributes({ 
                     "launch" => {
                                "programs" => ["webserver"]
                     },
                     "log" => {
                                "files" => ["/var/log/buildClient_webserver.log"]       
                     }
})
