#!/usr/bin/ruby
 
#requires
require 'rubygems'
require 'erb'
require 'json'
 
web_server_userdata = "./user-data/webstack/web_server-userdata.txt"
socialworker_userdata = "./user-data/webstack/socialworker-userdata.txt"
guestcleanup_userdata = "./user-data/webstack/guestcleanup-userdata.txt"
authworker_userdata = "./user-data/webstack/authworker-userdata.txt"
broker_userdata = "./user-data/webstack/broker-userdata.txt"
cacheworker_userdata = "./user-data/webstack/cacheworker-userdata.txt"
emailworker_userdata = "./user-data/webstack/cacheworker-userdata.txt"

output = "./json/web_stack_autoscale.tmpl.json" 
web_server_bootstrap_script = IO.read(web_server_userdata)
socialworker_bootstrap_script = IO.read(socialworker_userdata)
guestcleanup_bootstrap_script = IO.read(guestcleanup_userdata)
authworker_bootstrap_script = IO.read(authworker_userdata)
broker_bootstrap_script = IO.read(broker_userdata)
cacheworker_bootstrap_script = IO.read(cacheworker_userdata)
emailworker_bootstrap_script = IO.read(cacheworker_userdata)

cf_template_erb = IO.read("./templates/web_stack_autoscale.tmpl.erb")
cf_template = ERB.new(cf_template_erb).result(binding)

template_file = File.new(output,'w')
template_file.puts cf_template
template_file.close
puts output
