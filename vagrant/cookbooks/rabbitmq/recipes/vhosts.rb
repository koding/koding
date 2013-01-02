include_recipe "rabbitmq::default"

vhosts = %w( logs slugs stage stage-logs )

vhosts.each do |vhost|

    rabbitmq_vhost "#{vhost}" do
        action :add
    end

end
