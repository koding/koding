include_recipe "supervisord"
node['launch']['programs'].each do |kd_name|
   Chef::Log.info("DEBUG #{kd_name}")
   program  kd_name  do
     prog_name "#{kd_name}"
     command "/usr/bin/cake -c #{node['launch']['config']}"
     user "koding"
     directroy "#{node['kd_deploy']['deploy_dir']}/current"
   end
end
