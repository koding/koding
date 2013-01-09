name "web_server"
description "The  role for WEB servers"
run_list ["recipe[nginx]","recipe[nginx::koding_local]", "recipe[nodejs]","recipe[golang]","recipe[git]", "recipe[build-go]"]


default_attributes({ "nginx" => {
                                "worker_processes" => "1",
                                "backend_ports" => [3020],
                                "server_name" => "koding.local",
                                "maintenance_page" => "maintenance.html",
                                "static_files" => "/opt/koding/client"
                                }
                   })
