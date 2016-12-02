console.time 'Koding.com loaded'

kd    = require 'kd'
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

    if group
      kd.config.group = group
      # add Gitlab Config into kd.config if it's enabled for this team
      gitlab = window._runtimeOptions.gitlab ? {}
      if gitlab.team is group.slug and kd.config.environment isnt 'production'
        kd.config.gitlab = gitlab

    # BIG BANG
    new MainController group

  kd.config             or= {}
  kd.config.environment   = window._runtimeOptions.environment
  kd.config.recaptcha     = window._runtimeOptions.recaptcha
  kd.config.google        = window._runtimeOptions.google
  kd.config.domains       = window._runtimeOptions.domains
  kd.config.stripe        = window._runtimeOptions.stripe
  kd.config.groupName     = groupName = utils.getGroupNameFromLocation()

  if groupName is 'koding'
  then setGroup()
  else utils.checkIfGroupExists groupName, setGroup
