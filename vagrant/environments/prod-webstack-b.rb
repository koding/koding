name "prod-webstack-b"
description "The B webstack environment"

cookbook_versions({
    "sudo"          => "2.0.4",
    "local_users"   => "0.1.4",
    "apt"           => "1.7.0",
    "base_packages" => "0.1.0",
    "erlang"        => "1.1.2",
    "golang"        => "0.1.0",
    "mongodb"       => "0.1.0",
    "nginx"         => "1.1.2",
    "nodejs"        => "0.1.0",
    "ohai"          => "1.1.6",
    "rabbitmq"      => "1.7.0",
    "users"         => "1.3.0",
    "yum"           => "2.0.6",
    "kd_deploy"     => "0.1.12",
    "ntp"           => "1.3.2",
    "papertrail"    => "0.1.2",
    "zabbix-agent"  => "0.1.0"
})


default_attributes({ 
                     "launch" => {
                                 "config" => "rc",
                     },
                     "kd_deploy" => {
                                "revision_tag" => "koding-rc-27",
                                "release_action" => :deploy,
                                "deploy_dir" => '/opt/koding',
                                "rabbit_host" => "rabbit-b.prod.aws.koding.com",
                                "env" => "b"
                     },
                    "nginx" => {
                                "worker_processes" => "1",
                                "backend_ports" => [3020],
                                "server_name" => "koding.com",
                                "rc_server_name" => "rc.koding.com",
                                "maintenance_page" => "maintenance.html",
                                "static_files" => "/opt/koding/current/client"
                     },
                     "admins" => ["amykhailov","bkandemir","cblum","cthorn","dyasar"],
                     "devs" => ["snambi","ggoksel","rmusiol"]
                                
})
