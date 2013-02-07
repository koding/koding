
execute "build_modules" do
    user "koding"
    group "koding"
    cwd "#{node['kd_deploy']['deploy_dir']}/current"
    command "/usr/bin/npm i"
    creates "#{node['kd_deploy']['deploy_dir']}/current/node_modules"
    action :nothing
    environment ({'TMPDIR' => '/tmp/kd_tmp',
                  'HOME' => '/opt/koding'
                })
end

