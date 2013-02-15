define :remote_syslog, :enable => true do
  if params[:enable]
    params[:log_file].each do |log_file|
        execute "remote_syslog" do
          command "/usr/local/bin/remote_syslog --strip-color -p #{node["papertrail"]["port"]} #{log_file}"
          not_if do ::File.exists?("/var/run/remote_syslog.pid") end
        end
    end
  else
    execute "stop_remote_syslog" do
      command "/bin/kill `cat /var/run/remote_syslog.pid`"
      only_if do ::File.exists?("/var/run/remote_syslog.pid") end
    end
  end
end
