globals = require 'globals'

module.exports = (href, withOrigin = no) ->

  { slug, type } = globals.config.entryPoint

  href = if type is 'group' and slug isnt 'koding'
  then "#{slug}/#{href}"
  else href

  href = "#{global.location.origin}/#{href}"  if withOrigin

  return href
