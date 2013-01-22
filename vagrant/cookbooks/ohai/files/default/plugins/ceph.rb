#!/usr/bin/ruby
require 'rubygems'
require 'yaml'
require 'aws-sdk'


config = { :access_key_id => 'AKIAJO74E23N33AFRGAQ',
           :secret_access_key => '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',
}

AWS.config(config)
ec2 = AWS::EC2.new(:ec2_endpoint => 'ec2.us-east-1.amazonaws.com')
ec2.instances.filter('tag-key', 'CephType').filter('tag-value', 'mon').to_a.each do |instance|
    puts instance.id
end
