name "base_server"
description "The base role for all systems"
run_list ["recipe[yum::epel]","recipe[base_packages]"]
