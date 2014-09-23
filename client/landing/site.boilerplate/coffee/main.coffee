console.time 'Koding.com loaded'

# register appclasses
Home  = require './home/AppController'

# bootstrap app
MainController = require './core/maincontrollerloggedout'

do ->

  setConfig = ->

    KD.config or= {}

    KD.config.environment = if location.hostname is 'koding.com'\
                            then 'production' else 'development'

  registerRoutes = ->

    require './core/routes.coffee'


  setConfig()
  registerRoutes()
  # BIG BANG
  new MainController