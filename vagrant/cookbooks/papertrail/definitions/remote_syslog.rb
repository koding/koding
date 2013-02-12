define :remote_syslog, :enable => true do
  if params[:enable]
    params[:log_file].each do |log_file|
        execute "remote_syslog" do
          command "/usr/local/bin/remote_syslog -p #{node["papertrail"]["port"]} #{log_file}"
          not_if do ::File.symlink?("#{node['nginx']['dir']}/sites-enabled/#{params[:name]}") end
        end
    end
  elsif params[:disable]
    execute "stop_remote_syslog" do
      command "killall remote_syslog"
    end
  end
end
