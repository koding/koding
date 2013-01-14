{argv} = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")
{email, host} = KONFIG

email.protocol ?= if host is 'localhost' then 'http:' else 'https:'
email.protocol = email.protocol.split(':').shift()+':'

module.exports = email