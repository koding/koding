console.time 'Koding.com loaded'

require './core/utils'
require './core/KD.extend.coffee'

# register appclasses
require './about/AppController'
require './home/AppController'
require './login/AppController'
require './features/AppController'
require './legal/AppController'
require './pricing/AppController'
require './teams/AppController'
require './teamlanding/AppController'

# bootstrap app
MainController = require './core/maincontrollerloggedout'

do ->

  setConfig = ->

    KD.config or= {}

    KD.config.environment = if location.hostname is 'koding.com'\
                            then 'production' else 'development'

    KD.config.groupName   = KD.utils.getGroupNameFromLocation()

  registerRoutes = ->

    require './core/routes.coffee'
    require './login/routes.coffee'
    require './pricing/routes.coffee'
    require './legal/routes.coffee'
    require './features/routes.coffee'
    require './teams/routes.coffee'


  setConfig()
  registerRoutes()

  # BIG BANG
  new MainController
