name "dev_server"
description "The  role for dev servers"

run_list ["recipe[nginx]","recipe[nginx::koding_local]", "recipe[nodejs]","recipe[golang]",
            "recipe[rabbitmq]",
            "recipe[rabbitmq::mgmt_console]",
            "recipe[rabbitmq::third_party_plugins]",
            "recipe[rabbitmq::vhosts]",
            "recipe[rabbitmq::users]",
]


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
                     "rabbitmq" => {
                                "admin_password" => "dslkdscmckfjf55",
                                "user_password" => "djfjfhgh4455__5"
                     },
                     "launch" => {
                                "config" => "autoscale",
                                "programs" => ["buildClient webserver","goBroker","cacheworker","guestCleanup", "guestworker", "socialWorker" ]
                     }
})
