file "/etc/rabbit_host" do
  owner "koding"
  group "koding"
  mode "0644"
  content node["kd_deploy"]["rabbit_host"]
  action :create
end
