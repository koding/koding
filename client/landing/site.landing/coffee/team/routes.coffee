kd = require 'kd.js'

do ->

  handleRoot = -> kd.singletons.router.handleRoute '/'

  kd.registerRoutes 'Team',

    '/Team'       : handleRoot
    '/Team/Login' : -> kd.singletons.router.handleRoute '/Team'
    '/Team/:step' : ({ params : { step }, query }) ->

      { router } = kd.singletons
      router.openSection 'Team', null, null, (app) ->
        app.jumpTo step.toLowerCase(), query  if step
    '/Team/Recover' : ->

      { router } = kd.singletons
      router.openSection 'Team', null, null, (app) ->
        tab = app.jumpTo 'recover'
        tab.setFocus()

    '/Team/Reset/:token' : ({ params : { token } }) ->

      { router } = kd.singletons
      router.openSection 'Team', null, null, (app) ->
        tab = app.jumpTo 'reset'
        tab.form.addCustomData { recoveryToken : token }
