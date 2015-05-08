kd             = require 'kd'
globals        = require 'globals'

lazyrouter     = require 'app/lazyrouter'
checkFlag      = require 'app/util/checkFlag'
registerRoutes = require 'app/util/registerRoutes'


handleSection = (callback) ->
  kd.getSingleton('groupsController').ready ->

    if globals.config.environment isnt 'dev' or not checkFlag 'super-admin'
      kd.getSingleton('router').handleRoute '/'
      return

    kd.singleton('appManager').open 'Environments', callback

handle = ({params:{section}}) ->
  handleSection (app) ->
    # Reference for future requirements. ~ GG
    # app.loadSection title: section

module.exports = -> lazyrouter.bind 'environments', (type, info, state, path, ctx) ->

  switch type
    when 'home'
      info.params.section = 'Settings'

  handle info
