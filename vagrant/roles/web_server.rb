name "web_server"
description "The  role for WEB servers"

run_list ["recipe[nginx]","recipe[nginx::koding_local]", "recipe[nodejs]","recipe[golang]", "recipe[supervisord]"]

default_attributes({ "nginx" => {
                                "worker_processes" => "1",
                                "backend_ports" => [3020],
                                "server_name" => "as.koding.com",
                                "maintenance_page" => "maintenance.html",
                                "static_files" => "/opt/koding/current/client"
                     },
                     "kd_deploy" => {
                                "git_branch" => "master_autoscale",
                                "revision_tag" => "HEAD",
                                "release_action" => :deploy,
                                "deploy_dir" => '/opt/koding',
                     },
                     "launch" => {
                                "config" => "autoscale",
                                "programs" => ["buildClient webserver"]
                     }
})
