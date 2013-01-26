service node['mongodb']['service_name'] do
    case node[:platform]
    when "ubuntu"
        if node[:platform_version].to_f >= 9.10
            provider Chef::Provider::Service::Upstart
        end
    end
    action [:enable, :start]
    only_if do
        File.blockdev?(node['mongodb']['data_device'])
        File.blockdev?(node['mongodb']['log_device'])
    end
end
