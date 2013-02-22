
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

directory "/opt/koding" do
  owner "koding"
  group "koding"
  recursive true
end

git "/opt/koding" do
   user              "koding"
   group             "koding"
   repo              'git@10.0.0.25:koding.git' # gitlab server
   # branch            'virtualization'
   revision          "virtualization" # or "HEAD" or "TAG_for_1.0" 
   action            :sync
   ssh_wrapper       "/tmp/private_code/wrap-ssh4git.sh"
end
