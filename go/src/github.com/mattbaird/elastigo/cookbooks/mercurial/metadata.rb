maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Installs mercurial"
version           "0.8.0"

recipe "mercurial", "Installs mercurial"

%w{ debian ubuntu }.each do |os|
  supports os
end
