template "/etc/log_files.yml" do
  source "log_files.yml.erb"
  mode 0440
  owner "root"
  group "root"
  variables({
    :log_file => node["log"]["files"],
    :port => node["papertrail"]["port"]
  })
end

papertrail_log "restart papertrail" do
  action :nothing
  subscribes :restart, resources(:template => "/etc/log_files.yml" ), :immediately
end
