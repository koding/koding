name "ceph_osd"
description "The role for CEPH osd servers"
run_list ["role[base_server]","recipe[ohai]", "recipe[ceph]","recipe[ceph::osd]"]
