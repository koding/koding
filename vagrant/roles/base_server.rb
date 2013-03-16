name "base_server"
description "The base role for all systems"
run_list ["recipe[base_packages]","recipe[ntp]","recipe[hosts]","recipe[users]"]

env_run_lists "prod-webstack-a" => ["recipe[base_packages]","recipe[ntp]","recipe[hosts]","recipe[users]"],
              "prod-webstack-b" => ["recipe[base_packages]","recipe[ntp]","recipe[hosts]","recipe[users]"],
              "_default" => ["recipe[base_packages]","recipe[ntp]","recipe[hosts]","recipe[users]"] 
