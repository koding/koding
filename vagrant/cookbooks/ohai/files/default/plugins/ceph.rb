#!/usr/bin/ruby
require 'rubygems'
require 'aws-sdk'
require 'mash'


config = { :access_key_id => 'AKIAJO74E23N33AFRGAQ',
           :secret_access_key => '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',
}

AWS.config(config)
ec2 = AWS::EC2.new(:ec2_endpoint => 'ec2.us-east-1.amazonaws.com')

ceph = Mash.new
#ec2.instances.filter('tag-key', 'CephType').filter('tag-value', 'mon').to_a.each do |instance|
#    puts instance.id
#end

ceph[:mon_nodes] = ec2.instances.filter('tag-key', 'CephType').filter('tag-value', 'mon').to_a
ceph[:osd_nodes] = ec2.instances.filter('tag-key', 'CephType').filter('tag-value', 'osd').to_a
ceph[:client_nodes] = ec2.instances.filter('tag-key', 'CephType').filter('tag-value', 'client').to_a

puts ceph


