define :useradd do

    users = params[:users]
    users.keys.each do |username|
        
        home_dir = "/home/#{username}"

        if platform?("ubuntu")
            admin_grp = "admin"
        else
            admin_grp = "wheel"
        end

        group "#{username}" do
            gid users[username]["id"]
        end

        user "#{username}" do
            comment "Koding teammate #{username}"
            uid users[username]["id"]
            gid username
            home home_dir
            shell "/bin/bash"
            password "#{users[username]["pass"]}"
            supports :manage_home => true
        end


        if users[username]["sshkey"]
            directory "#{home_dir}/.ssh" do
                owner username
                group username
                mode "0700"
            end

            cookbook_file "#{home_dir}/.ssh/authorized_keys" do
                source "#{username}.pub"
                mode "0400"
                owner username
                group username
            end

        end

        group "#{admin_grp}" do
          action :modify
          members username
          append true
        end


    end

end
