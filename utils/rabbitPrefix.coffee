fs       = require 'fs'
nodePath = require 'path'

get =->
  projectRoot = nodePath.join(__dirname, '..')
  rabbitPrefix = ((
    try fs.readFileSync nodePath.join(projectRoot, '.rabbitvhost'), 'utf8'
    catch e
      hostname = require("os").hostname()
      console.log "You're missing the '.rabbitvhost' file in #{projectRoot}\nUsing your hostname: '#{hostname}' as identifier for RabbitMQ instead.\n"
      hostname
  ).trim())+"-dev"
  rabbitPrefix = rabbitPrefix.split('.').join('-')

  return rabbitPrefix

exports.get = get
