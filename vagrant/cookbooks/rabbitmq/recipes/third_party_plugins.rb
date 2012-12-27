include_recipe "rabbitmq::default"


remote_file "#{node['rabbitmq']['plugins_root']}/rabbit_presence_exchange-20120411.01.ez" do
    source "https://github.com/downloads/tonyg/presence-exchange/rabbit_presence_exchange-20120411.01.ez"
    checksum "c9efcb150780db3782114313da2313565b75461cd0d2dd37045434c03d5673dc"
end

third_party_plugins = %w( rabbit_presence_exchange )

third_party_plugins.each do |third_party_plugin|
  rabbitmq_plugin third_party_plugin do
    action :enable
    notifies :restart, resources(:service => node['rabbitmq']['service_name'])
  end
end


