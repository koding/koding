name "web_server_vagrant"
description "The  role for WEB servers"

run_list(   "recipe[apt]",
            "recipe[hosts]",
            "recipe[nginx]",
            "recipe[kd_deploy::nginx_conf]",
            "recipe[nodejs]",
            "recipe[papertrail]",
            "recipe[vagrant_ssh_tunnel]",
            "recipe[kd_run::vagrant]"
)
          
default_attributes({ 
                     "kd_deploy" => {"enabled"        => true,
                                     "release_action" => :deploy,
                                     "deploy_dir"     => '/opt/koding',
                                     "role"           => "web-server",
                                     "env"            => "vagrant",
                                     "backend_ports"  => [3020]
                      },
                      :rabbitmq => {
                                 :admin_password => "dslkdscmckfjf55",
                                 :user_password   => "djfjfhgh4455__5"
                      },
                      "vagrant_ssh_tunnel" => {
                                :remote_port => "5672"
                      },
                     "launch" => {
                                "programs"     => ["webserver","authWorker","goBroker","emailWorker","guestCleanup","socialWorker"],
                                "build_client" => true,
                                "build_gosrc"  => true,
                                "config" => "vagrant"
                     },
                     "log" => {
                                "files" => ["/var/log/upstart/webserver.log",
                                            "/var/log/chef/client.log"
                                           ]       
                     },
                     "nginx" => {
                                "worker_processes" => "1",
                                "backend_ports" => [3020],
                                "server_name" => "koding.local",
                                "rc_server_name" => "rc.koding.com",
                                "maintenance_page" => "maintenance.html",
                                "static_files" => "/opt/koding/current/client"
                     } 
})
