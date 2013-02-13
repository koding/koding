name "ceph_osd"
description "The role for CEPH osd servers"
run_list ["role[base_server]","recipe[aws-sdk::ruby]", "recipe[lvm]", "recipe[ceph]","recipe[ceph::osd]"]
