name "authworker"
description "The  role for authworker servers"

run_list ["recipe[nodejs]","recipe[golang]","recipe[supervisord]"]

default_attributes({ 
                     "kd_deploy" => {
                                "revision_tag" => "HEAD",
                                "release_action" => :deploy,
                                "deploy_dir" => '/opt/koding',
                     },
                     "launch" => {
                                "config" => "autoscale",
                                "programs" => ["authWorker"]
                     }
})
