kd = require 'kd'
isKoding = require 'app/util/isKoding'

module.exports = -> not isKoding()
