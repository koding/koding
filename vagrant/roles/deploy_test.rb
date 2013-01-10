name "deploy_test"
description "The  role for  servers"
run_list ["recipe[nodejs]","recipe[golang]","recipe[git]","recipe[kd_deploy]"]


default_attributes({ "kd_deploy" => {
                                "revision_tag" => "HEAD",
                                "release_action" => :deploy,
                                }
                   })

