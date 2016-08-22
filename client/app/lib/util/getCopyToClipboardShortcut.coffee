globals = require 'globals'

module.exports = -> if globals.os is 'mac' then '⌘ + C' else 'Ctrl + C'
