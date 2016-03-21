globals = require 'globals'

module.exports = (url) ->

  return url  if globals.config.environment is 'dev'
  return url  if /p.koding.com/.test url

  # let's use DOM for parsing the url
  parser = global.document.createElement("a")
  parser.href = url

  # build our new url, example:
  # old: http://54.164.174.218:3000/kite
  # new: https://koding.com/-/prodproxy/54.164.243.111/kite
  #           or
  #      http://localhost:8090/-/prodproxy/54.164.243.111/kite

  {protocol} = global.document.location


  proxy = if globals.config.environment is 'production'
  then 'prodproxy'
  else 'devproxy'

  subdomain = if globals.config.environment is 'production'
  then 'p'
  else 'dev-p'

  return "#{protocol}//#{subdomain}.koding.com/-/#{proxy}/#{parser.hostname}#{parser.pathname}"
