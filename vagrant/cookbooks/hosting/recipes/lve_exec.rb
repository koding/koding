cookbook_file "#{Chef::Config[:file_cache_path]}/lve_exec-1.1-2.el6.x86_64.rpm" do
    source "lve_exec-1.1-2.el6.x86_64.rpm"
    action :create_if_missing
end

rpm_package "#{Chef::Config[:file_cache_path]}/lve_exec-1.1-2.el6.x86_64.rpm" do
    action :install
end
