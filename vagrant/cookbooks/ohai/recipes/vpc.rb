# http://tickets.opscode.com/browse/OHAI-310

ohai "reload_ec2" do
    action :nothing
    plugin "ec2"
end

directory "/etc/chef/ohai/hints" do
    action :create
    recursive true
end

file "/etc/chef/ohai/hints/ec2.json" do
    action :create
    notifies :reload, resources(:ohai => "reload_ec2"), :immediately
end


