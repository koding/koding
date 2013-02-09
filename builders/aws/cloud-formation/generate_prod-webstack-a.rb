#!/usr/bin/ruby
 
#requires
require 'rubygems'
require 'erb'
require 'json'

env = "prod-webstack-a"

active = true

if active
    web_elb = "active-el-WebActiv-1RK6DY7CVVPZZ"
    broker_elb = "active-el-MqActive-YBOUL5Q88Z7Z"
else
    web_elb = "rc-elbs-WebRC-N60CZPG3IAD9"
    broker_elb = "rc-elbs-MqRC-YHVO2FRCJN0O"
end

roles = %w( authworker  broker  cacheworker  emailworker  guestcleanup  socialworker  web-server )

roles.each do |role|
    userdata = "./user-data/userdata.txt.erb"
    output = "./json/prod/#{env}/#{role}.tmpl.json" 
    userdata = IO.read(userdata)
    bootstrap_script = ERB.new(userdata).result(binding)

    cf_template_erb = IO.read("./templates/prod/#{env}/#{role}.tmpl.erb")
    cf_template = ERB.new(cf_template_erb).result(binding)

    template_file = File.new(output,'w')
    template_file.puts cf_template
    template_file.close
    puts output
end
