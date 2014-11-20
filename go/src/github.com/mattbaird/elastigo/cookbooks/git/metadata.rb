maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Installs git and/or sets up a Git server daemon"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "1.0.2"
recipe            "git", "Installs git"
recipe            "git::server", "Sets up a runit_service for git daemon"
recipe            "git::source", "Installs git from source"

%w{ amazon arch centos debian fedora redhat scientific ubuntu windows }.each do |os|
  supports os
end

supports "mac_os_x", ">= 10.6.0"

%w{ build-essential dmg runit yum }.each do |cb|
  depends cb
end
