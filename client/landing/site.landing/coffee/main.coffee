console.time 'Koding.com loaded'
require './core/utils'
require './core/KD.extend.coffee'

# register appclasses
About    = require './about/AppController'
Home     = require './home/AppController'
Login    = require './login/AppController'
Features = require './features/AppController'
Legal    = require './legal/AppController'
Pricing  = require './pricing/AppController'

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
    require './pricing/routes.coffee'




  setConfig()
  registerRoutes()

  # BIG BANG
  new MainController
