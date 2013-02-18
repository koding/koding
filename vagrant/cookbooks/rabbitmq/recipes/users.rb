include_recipe "rabbitmq::default"

rabbitmq_user "guest" do
  action :delete
end


# setup admin user
rabbitmq_user "sysadmin" do
    action :add
    password node["rabbitmq"]["admin_password"]
end

rabbitmq_user "sysadmin" do
  action :set_permissions
  vhost "/"
  permissions "\".*\" \".*\" \".*\""
end

rabbitmq_user "sysadmin" do
  action :set_user_tags
  user_tag "administrator"
end
# end of admin users



root_logs_users = %w( PROD-k5it50s4676pO9O
                      logger
                      prod-applications-kite
                      prod-broker
                      prod-databases-kite
                      prod-irc-kite
                      prod-os-kite
                      prod-sharedhosting-kite
                      prod-social
                      prod-webserver
                      prod-kite-webterm
                      prod-webterm-kite
                      prod-auth-worker
                      prod-authworker
                    )

root_logs_users.each do |root_logs_user|
    rabbitmq_user "#{root_logs_user}" do
        action :add
        password node["rabbitmq"]["user_password"]
    end

    vhosts = %w( / )
    vhosts.each do |vhost|
        rabbitmq_user "#{root_logs_user}" do
          action :set_permissions
          vhost "#{vhost}"
          permissions "\".*\" \".*\" \".*\""
        end
    end
end
# end of app users
