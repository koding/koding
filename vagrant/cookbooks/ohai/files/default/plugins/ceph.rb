###!/usr/bin/ruby
##require 'rubygems'
require 'aws-sdk'
##require 'mash'


config = { :access_key_id => 'AKIAJO74E23N33AFRGAQ',
           :secret_access_key => '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',
}

AWS.config(config)
ec2 = AWS::EC2.new(:ec2_endpoint => 'ec2.us-east-1.amazonaws.com')

ceph_types = %w( mon osd client )
provides "ceph"
ceph Mash.new
nodes = Array.new
ceph_types.each do |type|
    ec2.instances.filter('tag-key', 'CephType').filter('tag-value', type).each do |instance|
        nodes.push({:id => instance.id, :addr => instance.private_ip_address })
    end
    ceph["#{type}_nodes"] = nodes
    nodes.clear
end
