name "ceph"
description "The  role for CEPH mon servers"
run_list ["recipe[ntp]","recipe[ohai]", "recipe[ceph]","recipe[ceph::mon]"]
