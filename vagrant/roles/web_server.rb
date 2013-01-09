name "web_server"
description "The  role for WEB servers"
run_list ["recipe[nodejs]","recipe[golang]","recipe[git]", "recipe[build-go]"]
