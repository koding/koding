fs           = require 'fs'
nodePath     = require 'path'
projectRoot  = nodePath.join __dirname, '..'
rabbitPrefix = ((
  try fs.readFileSync nodePath.join(projectRoot, '.rabbitvhost'), 'utf8'
  catch e 
    hostname = require("os").hostname()
    console.log "You're missing the '.rabbitvhost' file in #{projectRoot}. I'll use your hostname #{hostname} instead."
).trim())+"-dev-#{version}"
rabbitPrefix = rabbitPrefix.split('.').join('-')

return rabbitPrefix
