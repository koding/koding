include_recipe "apt"

apt_repository "golang" do
  uri "http://ppa.launchpad.net/gophers/go/ubuntu"
  distribution node['lsb']['codename']
  components ["main"]
  keyserver "keyserver.ubuntu.com"
  key "9AD198E9"
end
