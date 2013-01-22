require 'net/http'
uri = URI('http://169.254.169.254/latest/meta-data/instance-id')
instance_id = Net::HTTP.get(uri)

default["ceph"]["version"] = "0.56.1-1precise"
default["ceph"]["server_id"] = instance_id 
