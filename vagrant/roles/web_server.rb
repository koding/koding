name "web_server"
description "The  role for WEB servers"
run_list ["recipe[nginx]", "recipe[nodejs]","recipe[golang]","recipe[git]"]


default_attributes({ "nginx" => {
                                "worker_processes" => "2",
                                }
                   })

