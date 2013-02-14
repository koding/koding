
directory "/tmp/private_code/.ssh" do
  owner "koding"
  group "koding"
  recursive true
end

cookbook_file "/tmp/private_code/wrap-ssh4git.sh" do
  action :create_if_missing
  owner "koding"
  group "koding"
  source "wrap-ssh4git.sh"
  mode 0700
end

cookbook_file "/tmp/private_code/.ssh/id_deploy" do
  action :create_if_missing
  owner "koding"
  group "koding"
  source "id_deploy"
  mode 0600
end


deploy_revision node['kd_deploy']['deploy_dir'] do
   user              "koding"
   group             "koding"
   deploy_to         node['kd_deploy']['deploy_dir']
   repo              'git@kodingen.beanstalkapp.com:/koding.git'
   revision          node['kd_deploy']['revision_tag'] # or "HEAD" or "TAG_for_1.0" 
   branch            node['kd_deploy']['git_branch']
   action            node['kd_deploy']['release_action']
   shallow_clone     true
   enable_submodules false
   migrate           false
   ssh_wrapper       "/tmp/private_code/wrap-ssh4git.sh"
   notifies          :run, "execute[build_modules]", :immediately
   notifies          :run, "execute[build_gosrc]", :immediately
   notifies          :run, "execute[build_client]", :immediately
   symlink_before_migrate.clear
   create_dirs_before_symlink.clear
   purge_before_symlink.clear
   symlinks.clear
end

node['launch']['programs'].each do |kd_name|
    prog_name = kd_name.gsub(/\s+/,"_")
    service "#{prog_name}" do
        action :nothing
        subscribes :restart, resources(:deploy_revision => node['kd_deploy']['deploy_dir'] ), :delayed
        provider Chef::Provider::Service::Upstart
    end
end
