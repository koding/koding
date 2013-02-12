node['launch']['programs'].each do |kd_name|
    prog_name = kd_name.gsub(/\s+/,"_")
    template "/etc/init/#{prog_name}.conf" do
        source "upstart.erb"
        mode 0440
        owner "root"
        group "root"
        variables({
            :description => "koding process #{prog_name}",
            :dir => "#{node['kd_deploy']['deploy_dir']}/current",
            :proc_owner => "koding",
            :command => "/usr/bin/cake -c #{node['launch']['config']} #{kd_name}"
        })
    end
    service "#{prog_name}" do
        supports :status => true, :restart => true, :reload => false
        action [ :enable, :start ]
        provider Chef::Provider::Service::Upstart
    end
end


