# Configuration File For Chef (chef-client)
#
# The chef-client program will connect the local system to the specified
# server URLs through a RESTful API to retrieve its configuration.
#
# By default, the client is configured to connect to a Chef Server
# as prompted by DebConf during package installation.
#
# The chef-client daemon reads this file by default, as set in
# /etc/default/chef-client.
#
# This is a Ruby DSL config file, and can embed regular Ruby code in addition to
# the configuration settings. Some settings use Ruby symbols, which are a value
# that starts with a colon. In Ruby, anything but 'false' or 'nil' is true. To
# set something to false:
#
# some_setting false
#

require 'net/http'
require 'ohai'

uri = URI('http://169.254.169.254/latest/meta-data/instance-id')
instance_id = Net::HTTP.get(uri)
o = Ohai::System.new()
o.all_plugins
ipaddr = ''
o['network']['interfaces']['eth0']['addresses'].keys.each do |key|
        if o['network']['interfaces']['eth0']['addresses'][key]['family'].eql?('inet')
                ipaddr = key
        end
end
node_name  "#{instance_id}--#{ipaddr}"

# log_level specifies the level of verbosity for output.
# valid values are: :debug, :info, :warn, :error, :fatal.
# Corresponds to chef-client -l

log_level          :info

# log_location specifies where the client should log to.
# valid values are: a quoted string specifying a file, or STDOUT with
# no quotes. STDOUT is a constant in Ruby.
# Corresponds to chef-client -L, and use -V with chef-client to ensure output
# also goes to STDOUT if this value is changed. The chef-client daemon is
# configured to log to /var/log/chef/client.log in /etc/default/chef-client.

log_location       STDOUT

# ssl_verify_mode specifies if the REST client should verify SSL certificates.
# valid values are :verify_none, :verify_peer. The default Chef Server
# installation on Debian will use a self-generated SSL certificate so this
# should be :verify_none unless you replace the certificate.

ssl_verify_mode    :verify_none

# chef_server_url specifies the Chef Server to connect to.
# valid values are any HTTP URL.
# Corresponds to chef-client -S

chef_server_url "https://api.opscode.com/organizations/koding"

# file_cache_path specifies where the client should cache cookbooks, server
# cookie ID, and openid registration data.
# valid value is any filesystem directory location.

file_cache_path    "/var/cache/chef"

# file_backup_path specifies where chef will store backups of replaced files
# from template, cookbook_file and remote_file resources.

file_backup_path   "/var/lib/chef/backup"

# pid_file specifies the location of where chef-client daemon should keep the pid
# file.
# valid value is any filesystem file location.

pid_file           "/var/run/chef/client.pid"

# cache_options sets options used by the moneta library for local cache
# for checksums of compared objects.

cache_options({ :path => "/var/cache/chef/checksums", :skip_expires => true})

# signing_ca_user is used when generating the certificates used by chef to
# set the owner of the keyfile. This is set to chef so services that run
# as the chef user can read the file.

#signing_ca_user "chef"
environment "prod"
validation_client_name "koding-validator"
validation_key "/etc/chef/koding-validator.pem"

json_attribs "/etc/chef/client-config.json"

# Mixlib::Log::Formatter.show_time specifies whether the log should
# contain timestamps.
# valid values are true or false. The printed timestamp is rfc2822, for example:
# Fri, 31 Jul 2009 19:19:46 -0600

Mixlib::Log::Formatter.show_time = true
