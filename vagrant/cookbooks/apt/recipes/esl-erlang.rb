
apt_repository "esl-erlang" do
  uri "http://binaries.erlang-solutions.com/debian"
  distribution node['lsb']['codename']
  components ["contrib"]
  key "http://binaries.erlang-solutions.com/debian/erlang_solutions.asc"
end
