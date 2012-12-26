name "rabbitmq_server"
description "The role for RabbitMQ servers"
run_list [
            "recipe[rabbitmq]",
            "recipe[rabbitmq::mgmt_console]",
            "recipe[rabbitmq::vhosts]",
            "recipe[rabbitmq::users]",
        ]
