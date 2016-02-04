console.time 'Koding.com loaded'

kd    = require 'kd.js'
utils = require './core/utils'

require './core/kd.extend.coffee'

# register appclasses
require './login/AppController'
require './team/AppController'
require './teams/AppController'

# bootstrap app
kookies        = require 'kookies'
MainController = require './core/maincontrollerloggedout'

do ->

  registerRoutes = ->

    require './core/routes.coffee'
    require './login/routes.coffee'
    require './teams/routes.coffee'
    require './team/routes.coffee'

  setGroup = (err, group) ->
    registerRoutes()
    kd.config.group = group  if group
    # BIG BANG
    new MainController group


  kd.config             or= {}
  kd.config.environment   = if location.hostname is 'koding.com' then 'production' else 'development'
  kd.config.groupName     = groupName = utils.getGroupNameFromLocation()
  kd.config.recaptcha     = window._runtimeOptions.recaptcha
  kd.config.google        = window._runtimeOptions.google
  kd.config.stripe        = window._runtimeOptions.stripe

  if groupName is 'koding'
  then setGroup()
  else utils.checkIfGroupExists groupName, setGroup
