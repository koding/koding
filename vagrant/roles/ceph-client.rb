name "ceph-client"
description "The role for Ceph Clients (accessing RBD storages e.g. for VM users)"
run_list ["recipe[base_packages::debian]", "recipe[build-essential]", "recipe[lxc]", "recipe[lxc::prepareVMRoot]", "recipe[ceph-base]", "recipe[ceph]","recipe[hosts]","recipe[kd_clone]","recipe[vagrant]"]

default_attributes({ 
                     "kd_clone" => {
                                "revision_tag" => "virtualization",
                                "release_action" => :sync,
                                "clone_dir" => '/opt/repo/koding',
                     }
})
