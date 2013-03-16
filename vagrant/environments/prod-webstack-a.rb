name "prod-webstack-a"
description "The A webstack environment"

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
    "kd_deploy"     => "0.1.13",
    "ntp"           => "1.3.2",
    "papertrail"    => "0.1.2",
    "zabbix-agent"  => "0.1.0"
})


default_attributes({ 
                     "launch" => {
                                 "config" => "production",
                     },
                     "kd_deploy" => {
                                "revision_tag" => "koding-prod-12",
                                "release_action" => :deploy,
                                "deploy_dir" => '/opt/koding',
                                "rabbit_host" => "rabbit-a.prod.aws.koding.com",
                                "env" => "a"
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
                     "devs" => ["ggoksel","rmusiol"]
})
