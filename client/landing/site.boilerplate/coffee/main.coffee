console.time 'Koding.com loaded'
require './core/utils'
require './core/KD.extend.coffee'

# register appclasses
Home  = require './home/AppController'
Login = require './login/AppController'

# bootstrap app
MainController = require './core/maincontrollerloggedout'

do ->

  setConfig = ->

    KD.config or= {}

    KD.config.environment = if location.hostname is 'koding.com'\
                            then 'production' else 'development'

  registerRoutes = ->

    require './core/routes.coffee'
    require './login/routes.coffee'


  setConfig()
  registerRoutes()
  # BIG BANG
  new MainController