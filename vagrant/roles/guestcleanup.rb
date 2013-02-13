name "guestcleanup"
description "The  role for guestcleanup servers"

env_run_lists "prod-webstack-a" => ["role[base_server]",
                                    "recipe[nodejs]",
                                    "recipe[golang]",
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
                                "programs" => ["guestCleanup"]
                     },
                     "log" => {
                                "files" => ["/var/log/guestCleanup.log"]       
                     }

})
