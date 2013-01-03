name "ceph_server"
description "The  role for CEPH servers"
run_list ["recipe[apt::ceph]","recipe[ceph::server]"]
