kd = require 'kd'
globals = require 'globals'


module.exports = getOAuthEndPoint = (provider) ->

  unless provider
    throw { message: 'Provider not passed to getOAuthEndPoint' }

  protocol = location.protocol
  group    = kd.singletons.groupsController.getCurrentGroup()
  { slug } = group
  host     = globals.config.domains.main

  "#{protocol}//#{slug}.#{host}/-/oauth/#{provider}/callback"
