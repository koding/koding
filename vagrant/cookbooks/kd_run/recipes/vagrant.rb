include_recipe "nodejs"

execute "screen -d -m cake -c vagrant run" do
	cwd "/opt/koding"
end