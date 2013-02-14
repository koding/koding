name "new-web-server"
description "The  role for WEB servers"

env_run_lists "prod-webstack-a" => ["role[base_server]",
                                    "recipe[nginx]",
                                    "recipe[kd_deploy::nginx_conf]",
                                    "recipe[nodejs]",
                                    "recipe[golang]",
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
                                "programs" => ["webserver"],
                                "build_client" => true,
                                 "config" => "production",
                     },
                     "log" => {
                                "files" => ["/var/log/upstart/webserver.log"]
                     },
                     "kd_deploy" => {
                                "git_branch" => "virtualization",
                                "revision_tag" => ":HEAD",
                                "release_action" => :deploy,
                                "deploy_dir" => '/opt/koding',
                                "rabbit_host" => "rabbit-a.prod.aws.koding.com"
                     },
                    "nginx" => {
                                "worker_processes" => "1",
                                "backend_ports" => [3020],
                                "server_name" => "koding.com",
                                "rc_server_name" => "new.koding.com",
                                "maintenance_page" => "maintenance.html",
                                "static_files" => "/opt/koding/current/client"
                     }
})
