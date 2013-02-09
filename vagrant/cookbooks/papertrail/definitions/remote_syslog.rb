define :remote_syslog, :enable => true do
  if params[:enable]
    execute "remote_syslog" do
      command "/usr/bin/remote_syslog -p #{node["papertrail"]["port"]} #{params[:log_file]}"
      not_if do ::File.symlink?("#{node['nginx']['dir']}/sites-enabled/#{params[:name]}") end
    end
  else
    execute "stop_remote_syslog" do
      command "killall remote_syslog"
    end
  end
end
