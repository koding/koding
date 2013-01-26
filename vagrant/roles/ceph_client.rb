name "ceph_client"
description "The  role for testing ceph clients "
run_list ["role[base_server]", "recipe[aws-sdk::ruby]", "recipe[ohai]", "recipe[ceph]","recipe[ceph::client]"]
