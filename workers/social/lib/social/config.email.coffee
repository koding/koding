{argv} = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")
{email, protocol} = KONFIG

host = email.host
email.protocol = protocol
email.protocol = email.protocol.split(':').shift()+':'

module.exports = email