isMacOS = require 'app/util/isMacOS'

module.exports = -> if isMacOS() then 'Cmd+C' else 'Ctrl+C'
