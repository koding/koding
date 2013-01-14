gem_package "mongo" do
  action :install
end

ruby_block "create-admin-user" do
  block do
    require "rubygems"
    require "mongo"

    if node['mongodb']['auth'].nil?
      Chef::Log.warn("auth attribute is false , skipping")
      next
    end
  end
end
