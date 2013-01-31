#!/usr/bin/ruby
 
#requires
require 'rubygems'
require 'erb'
require 'json'
type = ARGV[0]
if type.nil?
    STDERR.puts "Usage: #{$0} server_type "
    exit
end 

userdata = "./user-data/webstack_staging/#{type}-userdata.txt"
output = "./json/webstack_staging/#{type}.tmpl.json" 
bootstrap_script = IO.read(userdata)

cf_template_erb = IO.read("./templates/webstack/#{type}.tmpl.erb")
cf_template = ERB.new(cf_template_erb).result(binding)

template_file = File.new(output,'w')
template_file.puts cf_template
template_file.close
puts output
