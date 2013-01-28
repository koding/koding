# install ruby AWS sdk


if platform?("redhat", "centos", "fedora")
    gem_package "aws-sdk" do
        action :install
    end
end
   
if platform?("ubuntu")
   dependencies = %w( ruby-dev libxslt1-dev libxml2-dev  ) 
   dependencies.each do |pkg|
        apt_package pkg
   end
   gem_package "aws-sdk"
end

