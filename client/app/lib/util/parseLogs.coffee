globals = require 'globals'

module.exports = ->
  globals.__logs   ?= []
  l = '\n'; l += "#{line}\n"  for line in globals.__logs
  l += '\nEOF Logs.\n'
