hostname = "#{node["kd_deploy"]["env"]}-#{node["kd_deploy"]["role"]}-#{node["ipaddress"].gsub('.','-')}"
file '/etc/hostname' do
    content "#{hostname}\n"
    mode "0644"
end

if node[:hostname] != hostname
    execute "hostname #{hostname}"
    execute "/sbin/sysctl -w kernel.hostname=#{hostname}"
end



template "/etc/hosts" do
    source "hosts.erb"
    mode 0644
    owner "root"
    group "root"
    variables({
            :hostname => hostname
            })
end
