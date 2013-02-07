name "web_server"
description "The  role for WEB servers"

run_list ["role[base_server]","recipe[nginx]","recipe[kd_deploy::nginx_conf]", "recipe[nodejs]","recipe[golang]", "recipe[supervisord]","recipe[kd_deploy]"]

default_attributes({ 
                     "launch" => {
                                "programs" => ["buildClient webserver"]
                     }
})
