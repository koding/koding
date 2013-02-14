execute "build_client" do
    user "koding"
    group "koding"
    cwd "#{node['kd_deploy']['deploy_dir']}/current"
    command "/usr/bin/cake -c #{node['launch']['config']} buildClient"
    action :nothing
    only_if { node["launch"]["build_client"] }
end
