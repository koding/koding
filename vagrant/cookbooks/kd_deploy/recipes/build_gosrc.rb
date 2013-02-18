
execute "build_gosrc" do
    user "koding"
    group "koding"
    cwd "#{node['kd_deploy']['deploy_dir']}/current"
    command "/bin/bash go/build.sh"
    action :nothing
    only_if { node["launch"]["build_gosrc"] }
end

