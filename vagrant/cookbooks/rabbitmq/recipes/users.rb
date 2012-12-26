include_recipe "rabbitmq::default"

rabbitmq_user "guest" do
  action :delete
end


# setup admin user
rabbitmq_user "sysadmin" do
    action :add
    password 'hz2wdIsGfc63SUDv'
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



# setup app users
# PROD-k5it50s4676pO9O
rabbitmq_user "PROD-k5it50s4676pO9O" do
    action :add
    password 'hz2wdIsGfc63SUDv'
end

vhosts = %w( / logs slugs stage stage-logs )
vhosts.each do |vhost|
    rabbitmq_user "PROD-k5it50s4676pO9O" do
      action :set_permissions
      vhost "#{vhost}"
      permissions "\".*\" \".*\" \".*\""
    end
end

# -----------

rabbitmq_user "STAGE-sg46lU8J17UkVUq" do
    action :add
    password 'hz2wdIsGfc63SUDv'
end

vhosts = %w( stage )
vhosts.each do |vhost|
    rabbitmq_user "STAGE-sg46lU8J17UkVUq" do
      action :set_permissions
      vhost "#{vhost}"
      permissions "\".*\" \".*\" \".*\""
    end
end

# -----------

rabbitmq_user "logger" do
    action :add
    password 'hz2wdIsGfc63SUDv'
end

vhosts = %w( logs )
vhosts.each do |vhost|
    rabbitmq_user "logger" do
      action :set_permissions
      vhost "#{vhost}"
      permissions "\".*\" \".*\" \".*\""
    end
end
rabbitmq_user "logger" do
  action :set_user_tags
  user_tag "administrator"
end
# -----------


root_logs_users = %w( prod-applications-kite  prod-broker prod-databases-kite prod-irc-kite prod-os-kite prod-sharedhosting-kite prod-social prod-webserver prod-webterm-kite)

root_logs_users.each do |root_logs_user|
    rabbitmq_user "#{root_logs_user}" do
        action :add
        password 'hz2wdIsGfc63SUDv'
    end

    vhosts = %w( / logs )
    vhosts.each do |vhost|
        rabbitmq_user "#{root_logs_user}" do
          action :set_permissions
          vhost "#{vhost}"
          permissions "\".*\" \".*\" \".*\""
        end
    end
end
# end of app users
