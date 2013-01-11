name "base_server"
description "The base role for all systems"
run_list ["recipe[base_packages]","recipe[hosts]"]
