
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

directory node['kd_clone']['clone_dir'] do
  owner "koding"
  group "koding"
  recursive true
end

git node['kd_clone']['clone_dir'] do
   user              "koding"
   group             "koding"
   repository        'git@kodingen.beanstalkapp.com:/koding.git'
   # branch            'virtualization'
   revision          node['kd_clone']['revision_tag'] # or "HEAD" or "TAG_for_1.0" 
   action            node['kd_clone']['release_action']
   ssh_wrapper       "/tmp/private_code/wrap-ssh4git.sh"
end
