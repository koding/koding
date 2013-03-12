name "ceph-client"
description "The role for Ceph Clients (accessing RBD storages e.g. for VM users)"
# For AWS add kd_clone!
run_list ["recipe[base_packages::debian]", "recipe[build-essential]", "recipe[hosts]", "recipe[build-go]" , "recipe[lxc]", "recipe[lxc::prepareVMRoot]", "recipe[ceph-own]", "recipe[nodejs]", "recipe[users::sysadmins]", "recipe[users::developer]"]

default_attributes({ 
                     "kd_clone" => {
                                "revision_tag" => "virtualization",
                                "release_action" => :sync,
                                "clone_dir" => '/opt/repo/koding',
                     },
                     "vagrant" => true
})
