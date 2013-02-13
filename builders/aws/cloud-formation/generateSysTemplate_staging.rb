#!/usr/bin/ruby
 
#requires
require 'rubygems'
require 'erb'
require 'json'

env = "staging"


roles = %w( rabbitmq_server mongo_master mongo_slave )

roles.each do |role|
    userdata = "./user-data/userdata.txt.erb"
    output = "./json/staging/sys_#{env}/#{role}.tmpl.json" 
    userdata = IO.read(userdata)
    bootstrap_script = ERB.new(userdata).result(binding)

    cf_template_erb = IO.read("./templates/staging/sys_#{env}/#{role}.tmpl.erb")
    cf_template = ERB.new(cf_template_erb).result(binding)

    template_file = File.new(output,'w')
    template_file.puts cf_template
    template_file.close
    puts output
end
