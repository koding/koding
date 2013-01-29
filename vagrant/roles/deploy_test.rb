name "deploy_test"
description "The  role for  servers"
run_list ["recipe[nodejs]","recipe[golang]","recipe[kd_deploy]"]


default_attributes({ "kd_deploy" => {
                                "git_branch" => "master_autoscale",
                                "revision_tag" => "HEAD",
                                "release_action" => :deploy,
                                }
                   })

