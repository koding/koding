gem_package "mongo" do
  action :install
end

ruby_block "create-admin-user" do
  block do
    require "rubygems"
    require "mongo"
    until File.exists?("#{node['mongodb']['dbpath']}/local.0")
        sleep 1
        Chef::Log.info("waiting for file #{node['mongodb']['dbpath']}/local.0")
    end
    begin
        mongo_client = Mongo::MongoClient.new("127.0.0.1", 27017).db('admin')
    rescue Mongo::ConnectionFailure => ex
        sleep 5
        mongo_client = Mongo::MongoClient.new("127.0.0.1", 27017).db('admin')
    end
    mongo_client.add_user(node['mongodb']['admin_user'],node['mongodb']['admin_pass'])
    Chef::Log.info("waiting for file #{node['mongodb']['dbpath']}/admin.1")
    until File.exists?("#{node['mongodb']['dbpath']}/admin.1")
        Chef::Log.info("waiting for file #{node['mongodb']['dbpath']}/admin.1")
        sleep 1
    end
    Chef::Log.info("DEBUG: admin user has been created")
  end
  not_if do
    File.exists?("#{node['mongodb']['dbpath']}/admin.1")  
  end
  subscribes :create, resources(:service => node['mongodb']['service_name'] ), :immediately
  notifies :create, "template[#{node['mongodb']['configfile']}]", :delayed
  notifies :restart, resources(:service => node['mongodb']['service_name'] ), :delayed
  action :nothing
end

