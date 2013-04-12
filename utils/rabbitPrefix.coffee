fs       = require 'fs'
nodePath = require 'path'

projectRoot =->
  nodePath.join __dirname, '..'

hostname =->
  require("os").hostname()

get =->
  rabbitPrefix = ((
    try fs.readFileSync nodePath.join(projectRoot(), '.rabbitvhost'), 'utf8'
    catch e
      console.log "You're missing the '.rabbitvhost' file in #{projectRoot()}. I'll use your hostname #{hostname()} instead."
      return hostname()
  ).trim())+"-dev"
  rabbitPrefix = rabbitPrefix.split('.').join('-')

  return rabbitPrefix

exports.get = get
