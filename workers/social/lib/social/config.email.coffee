{ email, protocol } = require 'koding-config-manager'
email.protocol = protocol.split(':').shift() + ':'
module.exports = email
