name "prod-webstack-b"
description "The B webstack environment"

cookbook_versions({
    "local_users"   => "0.1.3",
    "apt"           => "1.7.0",
    "base_packages" => "0.1.0",
    "erlang"        => "1.1.2",
    "golang"        => "0.1.0",
    "mongodb"       => "0.1.0",
    "nginx"         => "1.1.2",
    "nodejs"        => "0.1.0",
    "ohai"          => "1.1.6",
    "rabbitmq"      => "1.7.0",
    "supervisord"   => "0.1.0",
    "users"         => "1.3.0",
    "yum"           => "2.0.6",
    "kd_deploy"     => "0.1.2",
    "ntp"           => "1.3.2"
})


default_attributes({ 
                     "launch" => {
                                 "config" => "rc",
                     },
                     "kd_deploy" => {
                                "git_branch" => "master_RC",
                                "revision_tag" => "koding-rc-1",
                                "release_action" => :deploy,
                                "deploy_dir" => '/opt/koding',
                                "rabbit_host" => "rabbit-b.prod.aws.koding.com"
                     },
                    "nginx" => {
                                "worker_processes" => "1",
                                "backend_ports" => [3020],
                                "server_name" => "koding.com",
                                "rc_server_name" => "rc.koding.com",
                                "maintenance_page" => "maintenance.html",
                                "static_files" => "/opt/koding/current/client"
                     }
})
