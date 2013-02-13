if platform?("ubuntu")
    apt_package "openjdk-7-jre" do
        action :install
    end
end
