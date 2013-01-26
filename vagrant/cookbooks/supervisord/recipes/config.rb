cookbook_file "/etc/supervisor/supervisord.conf" do
    source "supervisord.conf"
    notifies :restart, "service[#{node['supervisord']['service_name']}]"
end
