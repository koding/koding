{email} = require './config'

email.protocol ?= if host is 'localhost' then 'http:' else 'https:'
email.protocol = protocol.split(':').shift()+':'

module.exports = email