name "new-web-server"
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
                                    "recipe[nginx]",
                                    "recipe[kd_deploy::nginx_conf]",
                                    "recipe[nodejs]",
                                    "recipe[golang]",
                                    "recipe[papertrail]",
                                    "recipe[kd_deploy]",
                                    "recipe[zabbix-agent]"
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
                                "files" => ["/var/log/upstart/webserver.log",
                                            "/var/log/chef/client.log"
                                           ]
                     },
                     "kd_deploy" => {
                                "enabled" => true,
                                "git_branch" => "virtualization",
                                "release_action" => :deploy,
                                "deploy_dir" => '/opt/koding',
                                "rabbit_host" => "rabbit-a.prod.aws.koding.com",
                                "role" => "new-web-server",
                     },
                    "nginx" => {
                                "worker_processes" => "1",
                                "backend_ports" => [3020],
                                "server_name" => "new.koding.com",
                                "rc_server_name" => "rc.koding.com",
                                "maintenance_page" => "maintenance.html",
                                "static_files" => "/opt/koding/current/client"
                     }
})
