File.new(File.join(File.dirname(__FILE__), "vagrant.pem")).chmod(0600)

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu1304-64-1.0"
  config.vm.box_url = "https://s3.amazonaws.com/koding-vagrant/ubuntu1304-64-1.0.box"

  config.vm.network :private_network, ip: "10.5.5.2"
  config.vm.hostname = "vagrant"
  config.ssh.private_key_path = "vagrant.pem" # TODO remove

  config.vm.synced_folder ".", "/opt/koding"
  config.vm.synced_folder "saltstack", "/srv"
  config.vm.synced_folder "saltstack/vagrant-minion", "/etc/salt"

  config.vm.provider "virtualbox" do |v|
    v.name = "koding_#{Time.new.to_i}"
    v.customize ["setextradata", v.name, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/koding", "1"]
    v.customize ["modifyvm", v.name, "--memory", "1024", "--cpus", "2"]

    # second disk for ceph
    v.customize ["createhd",
      "--filename", File.expand_path("~/VirtualBox\ VMs/#{v.name}/box-disk2.vmdk"),
      "--size", "5000"
    ]
    v.customize ["storageattach", v.name,
      "--storagectl", "SATA Controller",
      "--port", "1",
      "--device", "0",
      "--type", "hdd",
      "--medium", File.expand_path("~/VirtualBox\ VMs/#{v.name}/box-disk2.vmdk")
    ]

    # TODO what is this disk used for?
    v.customize ["createhd",
      "--filename", File.expand_path("~/VirtualBox\ VMs/#{v.name}/box-disk3.vmdk"),
      "--size", "4000"
    ]
    v.customize ["storageattach", v.name,
      "--storagectl", "SATA Controller",
      "--port", "2",
      "--device", "0",
      "--type", "hdd",
      "--medium", File.expand_path("~/VirtualBox\ VMs/#{v.name}/box-disk3.vmdk")
    ]
  end

  config.vm.provision :salt do |salt|
    salt.run_highstate = true
    salt.verbose = true
  end
end

