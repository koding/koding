{ argv } = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")

module.exports = KONFIG
