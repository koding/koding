#!/usr/bin/ruby
 
#requires
require 'rubygems'
require 'erb'
require 'json'

unless ARGV.length == 2
  puts "Usage:"
  puts "  ruby generateDev.rb <subdomain> <git_branch>\n"
  exit
end

username = ARGV[0]
git_branch = ARGV[1]

git_rev = "HEAD"
env = "_default"


ssh_keys = %w()

Dir.foreach(ENV['HOME'] + '/.ssh') do |item|
  if item =~ /\.pub$/
    file = File.open(ENV['HOME'] + '/.ssh/' + item, "rb")
    contents = file.read
    ssh_keys << contents
  end
end

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
