# -*- mode: ruby -*-
# vi: set ft=ruby :

# setup username

local_user = Etc.getpwuid(Process.uid).name
private_ssh_key = "vagrant.pem"
template_centos_url = "https://s3.amazonaws.com/koding-vagrant-Lti5bj61mVnfMkhX/centos64.box"
template_cloudlinux_url = "https://s3.amazonaws.com/koding-vagrant-Lti5bj61mVnfMkhX/cloudlinux64.box"


if ENV["KODING_GIT_DIR"]
    koding_git_dir = ENV["KODING_GIT_DIR"]
else
    STDERR.puts "You must set KODING_GIT_DIR env variable 'export KODING_GIT_DIR='/path/to/git/dir'"
    exit 1
end

File.new(private_ssh_key).chmod(0600)


Vagrant::Config.run do |config|
    config.ssh.private_key_path = private_ssh_key

    # ---- Web server configuration -------
    config.vm.define :web do |web_config|

          web_config.vm.box = "centos64"
          web_config.vm.box_url = template_centos_url
          web_config.vm.network :hostonly, "10.0.0.2"
          web_config.vm.host_name = "web.#{local_user}.local"
          web_config.vm.forward_port 3000, 3000 # nodejs web server
          web_config.vm.share_folder "koding", "/opt/koding", koding_git_dir , :create => true, :map_uid => 'root', :map_gid => 'root'
          web_config.vm.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/koding", "1" ]
          web_config.vm.customize [
                                    "modifyvm", :id,
                                    "--memory", 1024,
                                    "--cpus", 2
                                  ]

          web_config.vm.provision :chef_solo do |chef|
            chef.cookbooks_path = "cookbooks/"
            chef.roles_path = "roles"
            chef.add_role("base_server")
            chef.add_role("web_server")
          end
    end
    # ----- end of Web server configuration -----



    # ---- RabbitMQ server configuration -------
    config.vm.define :rabbitmq do |rabbitmq_config|

          rabbitmq_config.vm.box = "centos64"
          rabbitmq_config.vm.box_url = template_centos_url
          rabbitmq_config.vm.host_name = "rabbitmq.#{local_user}.local"
          rabbitmq_config.vm.forward_port 55672, 55672 # rabbitmq management console
          rabbitmq_config.vm.network :hostonly, "10.0.0.3"
          rabbitmq_config.vm.customize [
                                    "modifyvm", :id,
                                    "--memory", 1024,
                                    "--cpus", 1
                                  ]

          rabbitmq_config.vm.provision :chef_solo do |chef|
            chef.cookbooks_path = "cookbooks/"
            chef.roles_path = "roles"
            chef.add_role("rabbitmq_server")
          end
    end
    # ----- end of RabbitMQ server configuration -----

    # ---- CloudLinux server configuration -------
    config.vm.define :cloudlinux do |cloudlinux_config|

          cloudlinux_config.vm.box = "cloudlinux64"
          cloudlinux_config.vm.box_url = template_cloudlinux_url
          cloudlinux_config.vm.host_name = "cloudlinux.#{local_user}.local"
          #cloudlinux_config.vm.forward_port 55672, 55672 
          cloudlinux_config.vm.network :hostonly, "10.0.0.4"
          cloudlinux_config.vm.customize [
                                    "modifyvm", :id,
                                    "--memory", 368,
                                    "--cpus", 1
                                  ]

          cloudlinux_config.vm.provision :chef_solo do |chef|
            chef.cookbooks_path = "cookbooks/"
            chef.roles_path = "roles"
            chef.add_role("base_server")
          end
    end
    # ----- end of cloudlinux server configuration -----

end
