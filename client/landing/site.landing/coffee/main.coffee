console.time 'Koding.com loaded'

# keep this on top
MainController = require './core/maincontrollerloggedout'

# register appclasses
About = require './about/AppController'
Home  = require './home/AppController'
Login = require './login/AppController'


# bootstrap app
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