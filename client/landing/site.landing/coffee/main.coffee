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
require './team/AppController'
require './teams/AppController'

# bootstrap app
MainController = require './core/maincontrollerloggedout'

do ->

  registerRoutes = ->

    require './core/routes.coffee'
    require './login/routes.coffee'
    require './pricing/routes.coffee'
    require './legal/routes.coffee'
    require './features/routes.coffee'
    require './teams/routes.coffee'
    require './team/routes.coffee'

  setGroup = (err, group) ->
    registerRoutes()
    KD.config.group = group  if group
    # BIG BANG
    new MainController group


  KD.config             or= {}
  KD.config.environment   = if location.hostname is 'koding.com' then 'production' else 'development'
  KD.config.groupName     = groupName = KD.utils.getGroupNameFromLocation()

  if groupName is 'koding'
  then setGroup()
  else KD.utils.checkIfGroupExists groupName, setGroup
