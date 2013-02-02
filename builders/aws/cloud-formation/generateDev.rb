#!/usr/bin/ruby
 
#requires
require 'rubygems'
require 'erb'
require 'json'

username = "bahadir"
git_branch = "vagrant"
git_rev = "HEAD"

env = "_default"

roles = %w( authworker  broker rabbitmq_server  cacheworker  emailworker  guestcleanup  socialworker  web_server )

roles.each do |role|
    userdata = "./user-data/dev-data.txt.erb"
    output = "./json/development/#{role}.tmpl.json" 
    userdata = IO.read(userdata)
    bootstrap_script = ERB.new(userdata).result(binding)

    cf_template_erb = IO.read("./templates/development/#{role}.tmpl.erb")
    cf_template = ERB.new(cf_template_erb).result(binding)

    template_file = File.new(output,'w')
    template_file.puts cf_template
    template_file.close
    puts output
end
