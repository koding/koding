name "ceph_mon"
description "The  role for CEPH mon servers"
run_list ["role[base_server]", "recipe[aws-sdk::ruby]", "recipe[ohai]", "recipe[ceph]","recipe[ceph::mon]"]
