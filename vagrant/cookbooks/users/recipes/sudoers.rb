# The purpose of this file is to enable passwordless sudo for sysadmins

cookbook_file "/etc/sudoers.d/99-koding" do
    source "sudoers"
    mode "440"
    owner "root"
    group "root"
end