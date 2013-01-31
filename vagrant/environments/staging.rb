name "staging"
description "The staging environment"

cookbook_versions({
    "local_users"   => "0.1.3",
    "apt"           => "1.7.0",
    "base_packages" => "1.1.0",
    "erlang"        => "1.1.2",
    "golang"        => "0.1.0",
    "golang"        => "0.1.0",
    "mongodb"       => "0.1.0",
    "nginx"         => "1.1.2",
    "nodejs"        => "0.1.0",
    "ohai"          => "1.1.6",
    "rabbitmq"      => "1.7.0",
    "supervisord"   => "0.1.0",
    "users"         => "1.3.0",
    "yum"           => "2.0.6",
    "kd_deploy"     => "0.1.1",
    "ntp"           => "1.3.2"
})


default_attributes({ 
                     "kd_deploy" => {
                                "git_branch" => "master_autoscale",
                                "revision_tag" => "HEAD",
                                "release_action" => :deploy,
                                "deploy_dir" => '/opt/koding',
                     }
})
