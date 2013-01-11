include_recipe "apt"

apt_repository "nodejs" do
  uri "http://ppa.launchpad.net/chris-lea/node.js/ubuntu"
  distribution node['lsb']['codename']
  components ["main"]
  keyserver "keyserver.ubuntu.com"
  key "C7917B12"
end
