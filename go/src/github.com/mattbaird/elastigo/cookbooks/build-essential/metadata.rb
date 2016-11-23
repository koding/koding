maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Installs C compiler / build tools"
version           "1.1.2"
recipe            "build-essential", "Installs packages required for compiling C software from source."

%w{ fedora redhat centos ubuntu debian amazon }.each do |os|
  supports os
end

supports "mac_os_x", ">= 10.6.0"
