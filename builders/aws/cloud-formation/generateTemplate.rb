#!/usr/bin/ruby
 
#requires
require 'rubygems'
require 'erb'
require 'json'
 
 
bootstrap_script = IO.read("./ceph_osd_userdata.txt")
cf_template_erb = IO.read("./ceph_cloud_formation.tmpl.erb")
cf_template = ERB.new(cf_template_erb).result(binding)
# 
template_file = File.new("ceph_cloud_formation.tmpl.json",'w')
template_file.puts cf_template
template_file.close
