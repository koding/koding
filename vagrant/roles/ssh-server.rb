name "ssh-server"
description "ssh-server"
run_list [
            "role[base_server]"
        ]
default_attributes({ 
                     "admins" => ["amykhailov","bkandemir","cblum","cthorn","dyasar"],
                     "devs" => ["snambi","ggoksel","rmusiol"]
})

