#!/usr/bin/ruby
 
#requires
require 'rubygems'
require 'erb'
require 'json'
 

type = ARGV[0]
if type.nil?
    STDERR.puts "Usage: #{$0} <mon|osd> "
    exit
end
output = "./json/#{type}_cloud_formation.tmpl.json" 
bootstrap_script = IO.read("./user-data/ceph_#{type}_userdata.txt")
cf_template_erb = IO.read("./templates/ceph_cloud_formation.tmpl.erb")
cf_template = ERB.new(cf_template_erb).result(binding)
# 
template_file = File.new(output,'w')
template_file.puts cf_template
template_file.close
puts output
