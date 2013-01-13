{argv} = require 'optimist'
# this will select the appropriate config file based on -c flag
module.exports = require('koding-config-manager').load("kite.sharedHosting.#{argv.c}")