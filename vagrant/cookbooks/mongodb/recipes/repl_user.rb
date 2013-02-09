
ruby_block "create-repl-user" do
  block do
    require "rubygems"
    require "mongo"
    until File.exists?("#{node['mongodb']['dbpath']}/local.0")
        sleep 1
        Chef::Log.info("waiting for file #{node['mongodb']['dbpath']}/local.0")
    end
    begin
        mongo_client = Mongo::MongoClient.new("127.0.0.1", 27017).db('local')
    rescue Mongo::ConnectionFailure => ex
        sleep 5
        mongo_client = Mongo::MongoClient.new("127.0.0.1", 27017).db('local')
    end
    mongo_client.add_user(node['mongodb']['repl_user'],node['mongodb']['repl_pass'])
    Chef::Log.info("DEBUG: replication user has been created")
  end
  not_if do
    File.exists?("#{node['mongodb']['dbpath']}/admin.1")  
  end
  subscribes :create, resources(:package => node['mongodb']['package_name'] ), :immediately
  action :nothing
end

