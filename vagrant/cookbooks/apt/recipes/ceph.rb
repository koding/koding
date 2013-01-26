
apt_repository "ceph" do
  uri "http://ceph.com/debian-bobtail"
  distribution node['lsb']['codename']
  components ["main"]
  key "https://raw.github.com/ceph/ceph/master/keys/release.asc"
end
