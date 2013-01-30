name "prod-leg-b"
description "The production B environment"

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
    "yum"           => "2.0.6"
})
