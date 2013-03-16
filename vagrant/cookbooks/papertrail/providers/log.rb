action :install do
  gem_package "remote_syslog" do
      action :install
  end
end

action :start do
  execute "start remote_syslog" do
    command "remote_syslog --configfile /etc/log_files.yml"
    not_if do ::File.exists?("/var/run/remote_syslog.pid") end
  end
end

action :stop do
  execute "stop remote_syslog" do
    command "/bin/kill `cat /var/run/remote_syslog.pid`"
    only_if do ::File.exists?("/var/run/remote_syslog.pid") end
  end
end

action :restart do
  execute "stop remote_syslog" do
    command "/bin/kill `cat /var/run/remote_syslog.pid`"
    only_if do ::File.exists?("/var/run/remote_syslog.pid") end
  end
  execute "start remote_syslog" do
    command "remote_syslog --configfile /etc/log_files.yml"
    not_if do ::File.exists?("/var/run/remote_syslog.pid") end
  end
end

action :delete do
  gem_package "remote_syslog" do
    action :remove
  end
  file "/etc/log_files.yml" do
    action :delete
  end
end
