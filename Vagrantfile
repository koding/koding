version = `VBoxManage --version 2> /dev/null` rescue "0"
if version < "4.2.18r88780" and ARGV[0] != "halt"
  print "\e[31mVirtualBox not installed or outdated. \e[39m"

  install = false
  if `uname`.strip == "Darwin" and system "tty > /dev/null"
    print "Download and install VirtualBox automatically? This will halt running Vagrant machines. (yN) "
    install = ($stdin.gets.strip == "y")
  end

  if not install
    puts "No automatic installation. Please download and install VirtualBox manually from:"
    puts "https://www.virtualbox.org/wiki/Downloads"
    exit! 1
  end

  system "vagrant halt" # may fail if Vagrant is not yet installed
  system "curl -L http://download.virtualbox.org/virtualbox/4.2.18/VirtualBox-4.2.18-88780-OSX.dmg > /tmp/VirtualBox.dmg" or exit! 1
  system "hdiutil attach /tmp/VirtualBox.dmg" or exit! 1
  system "sudo installer -pkg /Volumes/VirtualBox/VirtualBox.pkg  -target /" or exit! 1
  sleep 1 # somehow the installer stays active for some time
  system "hdiutil detach /Volumes/VirtualBox" or exit! 1
  puts "", "VirtualBox successfully installed.", ""
end

if $0 == "Vagrantfile" || Vagrant::VERSION < "1.2.7"
  print "Vagrant not installed or outdated. " unless $0 == "Vagrantfile"

  install = false
  if `uname`.strip == "Darwin" and system "tty > /dev/null"
    print "Download and install Vagrant automatically? (yN) "
    install = ($stdin.gets.strip == "y")
  end

  if not install
    puts "No automatic installation. Please download and install Vagrant manually from:"
    puts "http://downloads.vagrantup.com/tags/v1.2.7"
    exit! 1
  end

  system "curl -L http://files.vagrantup.com/packages/7ec0ee1d00a916f80b109a298bab08e391945243/Vagrant-1.2.7.dmg > /tmp/Vagrant.dmg" or exit! 1
  system "hdiutil attach /tmp/Vagrant.dmg" or exit! 1
  system "sudo installer -pkg /Volumes/Vagrant/Vagrant.pkg  -target /" or exit! 1
  sleep 1 # somehow the installer stays active for some time
  system "hdiutil detach /Volumes/Vagrant" or exit! 1
  puts "", "Vagrant successfully installed.", ""
  system "vagrant", *ARGV if $0 != "Vagrantfile"
  exit! 0
end

goVersion = `go version | cut -d " " -f 3` rescue "0"
if goVersion < "go1.2"
  puts "", "Your go version is outdated! Please install at least version 1.2 from https://code.google.com/p/go/downloads/list.\nRemove also the folder go/pkg after installing the new version.", ""
  exit! 1
end

provision = ENV.has_key? "PROVISION"
if provision
  if ARGV[0] != "plugin" and not `vagrant plugin list`.split("\n").include? "vagrant-salt (0.4.0)"
    system "vagrant plugin install vagrant-salt" or exit! 1
    puts "", "Salt plugin successfully installed.", ""
    system "vagrant", *ARGV
    exit! 0
  end
  if not File.exist? File.join(File.dirname(__FILE__), "saltstack")
    system "git clone git@git.in.koding.com:saltstack.git" or exit! 1
  end
end

Vagrant.configure("2") do |config|
  config.vm.define :default do |default|
    if provision
      default.vm.box = "raring-server-cloudimg-amd64-vagrant-disk1"
      default.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/raring/current/raring-server-cloudimg-amd64-vagrant-disk1.box"
    else
      default.vm.box = "koding-15"
      default.vm.box_url = "http://salt-master.in.koding.com/downloads/koding-15.box"
    end

    # private network for vm to reach to services on host computer
    config.vm.network "private_network", ip: "192.168.42.4"

    default.vm.network :forwarded_port, :guest =>  3021, :host =>  3021 # vmproxy
    default.vm.network :forwarded_port, :guest => 27017, :host => 27017 # mongodb
    default.vm.network :forwarded_port, :guest =>  5672, :host =>  5672 # rabbitmq
    default.vm.network :forwarded_port, :guest => 15672, :host => 15672 # rabbitmq api
    default.vm.network :forwarded_port, :guest => 8000, :host => 8000 # rockmongo
    default.vm.network :forwarded_port, :guest => 7474, :host => 7474 # neo4j
    default.vm.network :forwarded_port, :guest => 6379, :host => 6379 # redis
    default.vm.network :forwarded_port, :guest => 9200, :host => 9200 # elastic search
    default.vm.network :forwarded_port, :guest => 3999, :host => 3999 # proxy kite
    default.vm.network :forwarded_port, :guest => 4000, :host => 4000 # kontrol kite
    default.vm.network :forwarded_port, :guest => 4005, :host => 4005 # provisioning kite
    default.vm.network :forwarded_port, :guest => 5000, :host => 5000 # oskite
    default.vm.network :forwarded_port, :guest => 5432, :host => 5432 # postgresql
    default.vm.network :forwarded_port, :guest => 5001, :host => 5001 # terminal kite
    default.vm.hostname = "vagrant"

    default.vm.synced_folder ".", "/opt/koding"
    default.vm.synced_folder "saltstack", "/srv" if provision

    default.vm.provider "virtualbox" do |v|
      v.name = "koding_#{Time.new.to_i}"
      v.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/koding", "1"]
      v.customize ["modifyvm", :id, "--memory", "2048", "--cpus", "2"]
    end

    if provision
      default.vm.provision :shell, :inline => "
        apt-get --assume-yes install python-pip python-dev
        pip install mako
      "
      default.vm.provision :salt do |salt|
        salt.verbose = true
        salt.minion_config = "saltstack/vagrant-minion"
        salt.run_highstate = true
      end
    end
  end

end
