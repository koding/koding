module.exports = class Feeder
	Broker = require 'broker'

	dbUrl = switch argv.d or 'mongohq-dev'
	  when "local"
	    "mongodb://localhost:27017/koding?auto_reconnect"
	  when "sinan"
	    "mongodb://localhost:27017/kodingen?auto_reconnect"
	  when "vpn"
	    "mongodb://kodingen_user:Cvy3_exwb6JI@10.70.15.2:27017/kodingen?auto_reconnect"
	  when "beta"
	    "mongodb://beta_koding_user:lkalkslakslaksla1230000@localhost:27017/beta_koding?auto_reconnect"
	  when "beta-local"
	    "mongodb://beta_koding_user:lkalkslakslaksla1230000@web0.beta.system.aws.koding.com:27017/beta_koding?auto_reconnect"
	  when "wan"
	    "mongodb://kodingen_user:Cvy3_exwb6JI@184.173.138.98:27017/kodingen?auto_reconnect"
	  when "mongohq-dev"
	    "mongodb://dev:633939V3R6967W93A@alex.mongohq.com:10065/koding_copy?auto_reconnect"

	constructor: (options) ->
		options.host ?= "localhost"
		options.login ?= "guest"
		options.password ?= "guest"
		@mq = new Broker options
		

