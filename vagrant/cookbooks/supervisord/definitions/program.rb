define :program do

    prog_name    = params[:prog_name].gsub(/\s+/,"_")
    command = params[:command]
    user    = params[:user]
    directroy = params[:directroy]
    

    template "#{node['supervisord']['config_dir']}/#{prog_name}.conf" do
        source "program.conf.erb"
        variables(
                :name => prog_name,
                :command => "#{command} #{params[:prog_name]}",
                :user => user,
                :directroy => directroy
        )
        owner "root"
        group "root"
        mode "0644"
        action :create
    end

    execute "/usr/bin/supervisorctl update #{prog_name}" do
       action :nothing
       subscribes :run, resources(:template => "#{node['supervisord']['config_dir']}/#{prog_name}.conf" ), :immediately 
    end

end
