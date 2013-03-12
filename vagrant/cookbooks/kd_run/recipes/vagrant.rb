include_recipe "nodejs"

execute "build_modules" do
    user "vagrant"
    group "vagrant"
    cwd "/opt/koding"
    command "/usr/bin/npm i"
    creates "/opt/koding/node_modules"
    environment ({'TMPDIR' => '/tmp/kd_tmp',
                  'HOME' => '/opt/koding'
                })
end

execute "run_vagrant" do
	cwd "/opt/koding"
	command "screen -d -m cake -c vagrant run"
end