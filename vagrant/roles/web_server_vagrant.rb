name "web_server_vagrant"
description "The  role for WEB vagrant servers"

run_list ["recipe[nginx]","recipe[golang]", "recipe[kd_run::vagrant]"]

default_attributes({ "nginx" => {
                                "worker_processes" => "1",
                                "backend_ports" => [3020],
                                "server_name" => "koding.local",
                                "maintenance_page" => "maintenance.html",
                                "static_files" => "/opt/koding/client"
                     }
})
