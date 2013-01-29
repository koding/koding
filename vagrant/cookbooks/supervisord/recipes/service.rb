service node['supervisord']['service_name'] do
    action [:start, :enable]
end
