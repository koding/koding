if Vagrant::VERSION < "1.2.1"
  print "Sorry, but your vagrant version is outdated. "
  install = false
  if `uname`.strip == "Darwin"
    print "Download and install the new version? (yN) "
    install = ($stdin.gets.strip == "y")
  end

  if install
    system "wget -O /tmp/Vagrant.dmg http://files.vagrantup.com/packages/a7853fe7b7f08dbedbc934eb9230d33be6bf746f/Vagrant-1.2.1.dmg"
    system "hdiutil attach /tmp/Vagrant.dmg"
    system "sudo installer -pkg /Volumes/Vagrant/Vagrant.pkg  -target /"
    sleep 1 # somehow the installer stays active for some time
    system "hdiutil detach /Volumes/Vagrant"
    puts "", "Vagrant successfully installed. Please run your command again."
  else
    puts "Please download and install manually from:"
    puts "http://downloads.vagrantup.com/tags/v1.2.1"
  end

  exit 1
end

provision = ENV.has_key? "PROVISION"
if provision
  if ARGV[0] != "plugin" and not `vagrant plugin list`.split("\n").include? "vagrant-salt (0.4.0)"
    system "vagrant plugin install vagrant-salt"
    puts "", "Plugin successfully installed. Please run your command again."
    exit 1
  end
  if not File.exist? File.join(File.dirname(__FILE__), "saltstack")
    system "git clone git@git.in.koding.com:saltstack.git"
  end
end

Vagrant.configure("2") do |config|
  if provision
    config.vm.box = "raring-server-cloudimg-amd64-vagrant-disk1"
    config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/raring/current/raring-server-cloudimg-amd64-vagrant-disk1.box"
  else
    config.vm.box = "ubuntu1304-64-1.0"
    config.vm.box_url = "http://d1vrbmdcyl9zrp.cloudfront.net/ubuntu1304-64-1.0.box"
  end

  config.vm.network :private_network, ip: "10.5.5.2"
  config.vm.hostname = "vagrant"

  config.vm.synced_folder ".", "/opt/koding"
  config.vm.synced_folder "saltstack", "/srv" if provision

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
      "--storagectl", "SATAController",
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
      "--storagectl", "SATAController",
      "--port", "2",
      "--device", "0",
      "--type", "hdd",
      "--medium", File.expand_path("~/VirtualBox\ VMs/#{v.name}/box-disk3.vmdk")
    ]
  end

  if provision
    config.vm.provision :shell, :inline => "
      apt-get --assume-yes install python-pip python-dev
      pip install mako
    "
    config.vm.provision :salt do |salt|
      salt.verbose = true
      salt.minion_config = "saltstack/vagrant-minion"
      salt.run_highstate = true
    end
  end
end
