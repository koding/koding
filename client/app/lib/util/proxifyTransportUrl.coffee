globals = require 'globals'

module.exports = (url)->

  return url  if /p.koding.com/.test url

  # let's use DOM for parsing the url
  parser = global.document.createElement("a")
  parser.href = url

  # build our new url, example:
  # old: http://54.164.174.218:3000/kite
  # new: https://koding.com/-/userproxy/54.164.243.111/kite
  #           or
  #      http://localhost:8090/-/userproxy/54.164.243.111/kite

  proxy = {
    dev        : 'devproxy'
    production : 'prodproxy'
    sandbox    : 'sandboxproxy'
  }[globals.config.environment] or 'devproxy'

  {protocol} = global.document.location

  return "#{protocol}//p.koding.com/-/#{proxy}/#{parser.hostname}/kite"
