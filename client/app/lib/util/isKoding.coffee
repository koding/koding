globals = require 'globals'

module.exports = (group) ->
  return  if group
    group.slug is 'koding'
  else
    globals.config.entryPoint?.slug is 'koding'
