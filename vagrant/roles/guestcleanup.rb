name "guestcleanup"
description "The  role for guestcleanup servers"

run_list ["role[base_server]","recipe[nodejs]","recipe[golang]", "recipe[supervisord]","recipe[kd_deploy]"]

default_attributes({ 
                     "launch" => {
                                "programs" => ["guestCleanup"]
                     }
})
