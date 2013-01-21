name "guestworker"
description "The  role for guestworker"

run_list ["recipe[nodejs]","recipe[golang]", "recipe[supervisord]" ]

default_attributes({ 
                     "kd_deploy" => {
                                "revision_tag" => "HEAD",
                                "release_action" => :deploy,
                                "deploy_dir" => '/opt/koding',
                     },
                     "launch" => {
                                "config" => "autoscale",
                                "programs" => ["guestworker"]
                     }
})
