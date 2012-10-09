{email, host} = require './config'

email.protocol ?= if host is 'localhost' then 'http:' else 'https:'
email.protocol = email.protocol.split(':').shift()+':'

module.exports = email