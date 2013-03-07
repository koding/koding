include_recipe "nodejs"

execute "cake -c vagrant run" do
	cwd "/opt/koding"
end