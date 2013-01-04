
directory "/tmp/private_code/.ssh" do
  owner "root"
  recursive true
end

cookbook_file "/tmp/private_code/wrap-ssh4git.sh" do
  source "wrap-ssh4git.sh"
  owner "root"
  mode 0700
end

cookbook_file "/tmp/private_code/.ssh/id_deploy" do
    source "id_deploy"
    owner "root"
    mode 0600
end


KODING_ROOT = '/opt/koding/'
deploy_revision KODING_ROOT do
    deploy_to         KODING_ROOT
    repo              'git@kodingen.beanstalkapp.com:/koding.git'
    revision          node['kd_deploy']['revision_tag'] # or "HEAD" or "TAG_for_1.0" 
    action            node['kd_deploy']['release_action']
    shallow_clone     true
    enable_submodules false
    migrate           false
    ssh_wrapper       "/tmp/private_code/wrap-ssh4git.sh"
end
