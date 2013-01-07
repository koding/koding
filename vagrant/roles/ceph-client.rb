name "ceph-client"
description "The role for Ceph Clients (accessing RBD storages e.g. for VM users)"
run_list ["recipe[base_packages::debian]", "recipe[build-essential]", "recipe[git]", "recipe[lxc]", "recipe[lxc::prepareVMRoot]", "recipe[ceph-base]", "recipe[ceph]"]
